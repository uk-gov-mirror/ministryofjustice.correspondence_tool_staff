module ConfigurableStateMachine
  class Machine

    def initialize(config:, kase:)
      @config = config
      @kase = kase
    end

    def configurable?
      true
    end

    def initial_state
      @config.initial_state
    end

    def current_state
      @kase.current_state || initial_state
    end

    def permitted_events(current_user_or_id)
      user = current_user_or_id.instance_of?(User) ? current_user_or_id : User.find(current_user_or_id)
      events = permitted_events_for_role_and_user(user: user, state: @kase.current_state)
      events.flatten.uniq.sort
    end

    # determines whether or not an event can be triggered
    # params:
    # * event_name: The event to be triggered
    # * metadata:   A hash, which must contain the key :acting_user or :acting_user_id.  May also contain
    #               :acting_team or :acting_team_id which will be used to determine roles if roles not set
    # * roles:      Either a string denoting the role, or an array of roles, or nil.  If nil, the role will be determined
    #               from either the acting_team or acting_user
    #
    def can_trigger_event?(event_name:, metadata:, roles: nil)
      result = false
      roles = [roles] if roles.is_a?(String)
      roles = extract_roles_from_metadata(metadata) if roles.nil?
      user = extract_user_from_metadata(metadata)
      roles.each do |role|
        role_config = @config.user_roles[role]
        next if role_config.nil?
        role_state_config =  role_config.states[@kase.current_state]
        if key_present_but_nil?(role_state_config, event_name.to_sym)
          result = true
        else
          result = event_present_and_triggerable?(role_state_config: role_state_config, event: event_name, user: user)
        end
        break if result == true
      end
      result
    end

    # intercept trigger event  methods, whcih all end in a !
    #
    def method_missing(method, *args)
      if method.to_s =~ /(.+)!$/
        event_name = $1
        trigger_event(event: event_name, params: args.first)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method.to_s =~ /(.+)!$/ || super
    end



    private

    def event_present_and_triggerable?(role_state_config:, event:, user:)
      config = role_state_config[event]
      return false if config.nil?
      if config.to_h.key?(:if)
        return predicate_is_true?(predicate: config.if, user: user) ? true : false
      else
        return true
      end
    end

    def key_present_but_nil?(config, key)
      config.to_h.key?(key) && config[key].nil?
    end



    # in a transaction, write the case transition record, and transition the case
    # params are guaranteed to have the following keys:
    # * :acting_user (this corresponds to the current_user)
    # * :acting_team
    #
    def trigger_event(event:, params:)
      raise ::ConfigurableStateMachine::ArgumentError.new(kase: @kase, event: event, params: params) if !params.key?(:acting_user) || !params.key?(:acting_team)
      role =  params[:acting_team].role
      user_role_config = @config.user_roles[role]
      raise InvalidEventError.new(kase: @kase, user: params[:acting_user], event: event) if user_role_config.nil?
      state_config = user_role_config.states[@kase.current_state]
      raise InvalidEventError.new(kase: @kase, user: params[:acting_user], event: event) if state_config.nil?
      event_config = state_config[event]
      if can_trigger_event?(event_name: event, metadata: params)
        ActiveRecord::Base.transaction do
          to_state = find_destination_state(event_config: event_config)
          CaseTransition.unset_most_recent(@kase)
          write_transition(event: event, to_state: to_state, params: params)
          @kase.update!(current_state: to_state)
        end
      else
        raise InvalidEventError.new(kase: @kase, user: params[:acting_user],  event: event)
      end
    end


    def extract_roles_from_metadata(metadata)
      team = extract_team_from_metadata(metadata)
      user = extract_user_from_metadata(metadata)
      if team.nil?
        user.roles
      else
        user.roles_for_team(team).map(&:role)
      end
    end

    def extract_team_from_metadata(metadata)
      if metadata.key?(:acting_team)
        metadata[:acting_team]
      elsif metadata.key?(:acting_team_id)
        Team.find(metadata[:acting_team_id])
      else
        nil
      end
    end


    def extract_user_from_metadata(metadata)
      if metadata.key?(:acting_user_id)
        User.find(metadata[:acting_user_id])
      else
        metadata[:acting_user]
      end
    end

    def permitted_events_for_role_and_user(user:, state:)
      events = []
      user.roles.each do |role|
        role_config = @config.user_roles[role]
        next if role_config.nil?
        role_state_config = role_config.states[state]
        role_state_config.to_h.keys.each do |event|
          event_config = role_state_config[event]
          events << event if event_triggerable_for_user?(event_config: event_config, user: user)
        end
      end
      events
    end

    def event_triggerable_for_user?(event_config:, user:)
      if event_config.to_h.key?(:if)
        predicate_is_true?(predicate: event_config[:if], user: user)
      else
        true
      end
    end

    def predicate_is_true?(predicate:, user:)
      klass, method = predicate.split('#')
      predicate_oject = klass.constantize.new(user: user, kase: @kase)
      predicate_oject.__send__(method)
    end

    def find_destination_state(event_config:)
      event_config.to_h.key?(:transition_to) ? event_config.transition_to : @kase.current_state
    end

    def write_transition(event:, to_state:, params:)
      attrs = {
        event: event,
               to_state: to_state,
               sort_key: CaseTransition.next_sort_key(@kase),
               most_recent: true,
        acting_user_id: params[:acting_user]&.id,
        acting_team_id: params[:acting_team]&.id,
        target_user_id: params[:target_user]&.id,
        target_team_id: params[:target_team]&.id,
      }
      %i{ acting_user acting_team target_user target_team }.each do |key|
        params.delete(key)
      end
      @kase.transitions.create!(attrs.merge(params))
    end
  end
end
