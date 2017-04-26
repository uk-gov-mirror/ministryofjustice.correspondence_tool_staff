require 'rails_helper'

RSpec::Matchers.define :trigger_the_event do |event|
  match do |code|
    allow(@state_machine).to receive(:trigger!)
    code.call
    expect(@state_machine)
      .to have_received(:trigger!).with(
            event,
            @parameters.merge({ event: event }),
          )
  end

  chain :on_state_machine do |state_machine|
    @state_machine = state_machine
  end

  chain :with_parameters do |params|
    @parameters = params
  end

  supports_block_expectations

  failure_message do |_code|
    "expected #{@state_machine} to have received trigger!(#{event}, #{@parameters.merge({event: event})})"
  end
end


RSpec::Matchers.define :transition_from do |from_state|
  match do |event|
    expect(event[:transitions]).to have_key from_state.to_s
    expect(event[:transitions][from_state.to_s]).to include @to_state
  end

  chain :to do |to_state|
    @to_state = to_state.to_s
  end
end

RSpec::Matchers.define :require_permission do |permission|
  match do |event|
    expect_any_instance_of(CasePolicy).to receive(permission).and_return(true)
    event[:callbacks][:guards].each do |guard|
      expect do
        guard.call(@object, nil, @options)
        @permission_received = true
      end .not_to raise_error
    end
  end

  chain :using_options do |options|
    @options = options
  end

  chain :using_object do |object|
    @object = object
  end
end

# helper class to make example groups a bit more readable below
def event(event_name)
  CaseStateMachine.events[event_name]
end

RSpec.describe CaseStateMachine, type: :model do
  let(:kase)               { create :case }
  let(:state_machine) do
    CaseStateMachine.new(
      kase,
      transition_class: CaseTransition,
      association_name: :transitions
    )
  end
  let(:managing_team)      { create :managing_team }
  let(:manager)            { managing_team.managers.first }
  let(:responding_team)    { create :responding_team }
  let(:responder)          { responding_team.responders.first }
  let(:new_case)           { create :case }
  let(:assigned_case)      { create :assigned_case,
                                 responding_team: responding_team }
  let(:case_being_drafted) { create :case_being_drafted,
                                    responder: responder,
                                    responding_team: responding_team }
  let(:case_with_response) { create :case_with_response,
                                    responder: responder,
                                    responding_team: responding_team }
  let(:responded_case)     { create :responded_case,
                             responder: responder,
                             responding_team: responding_team }
  let(:closed_case)        { create :closed_case,
                             responder: responder,
                             responding_team: responding_team }

  context 'after transition' do
    let(:t1) { Time.new(2017, 4, 25, 10, 13, 55) }
    let(:t2) { Time.new(2017, 4, 27, 23, 14, 2) }
    it 'stores current state and time of transition on the case record' do
      Timecop.freeze(t1) do
        kase = create :case, received_date: Time.now - 1.day
        expect(kase.current_state).to eq 'unassigned'
        expect(kase.last_transitioned_at).to eq t1
      end
      Timecop.freeze(t2) do
        kase.assign_responder(manager, responding_team)
      end
      expect(kase.current_state).to eq 'awaiting_responder'
      expect(kase.last_transitioned_at).to eq t2
    end
  end

  describe event(:assign_responder) do
    it { should transition_from(:unassigned).to(:awaiting_responder) }
    it { should require_permission(:can_assign_case?)
                  .using_options(user_id: manager.id)
                  .using_object(new_case) }
  end

  describe event(:flag_for_clearance) do
    it { should transition_from(:awaiting_responder).to(:awaiting_responder) }
    it { should transition_from(:drafting).to(:drafting) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should require_permission(:can_flag_for_clearance?)
                  .using_options(user_id: manager.id)
                  .using_object(assigned_case) }
  end

  describe event(:accept_responder_assignment) do
    it { should transition_from(:awaiting_responder).to(:drafting) }
    it { should require_permission(:can_accept_or_reject_case?)
                  .using_options(user_id: responder.id)
                  .using_object(assigned_case) }
  end

  describe event(:reject_responder_assignment) do
    it { should transition_from(:awaiting_responder).to(:unassigned) }
    it { should require_permission(:can_accept_or_reject_case?)
                  .using_options(user_id: responder.id)
                  .using_object(assigned_case) }
  end

  describe event(:add_responses) do
    it { should transition_from(:drafting).to(:awaiting_dispatch) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should require_permission(:can_add_attachment?)
                  .using_options(user_id: responder.id)
                  .using_object(case_being_drafted) }
  end

  describe event(:remove_response) do
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should require_permission(:can_remove_attachment?)
                  .using_options(user_id: responder.id)
                  .using_object(case_with_response) }
  end

  describe event(:remove_last_response) do
    it { should transition_from(:awaiting_dispatch).to(:drafting) }
    it { should require_permission(:can_remove_attachment?)
                  .using_options(user_id: responder.id)
                  .using_object(case_with_response) }
  end

  describe event(:respond) do
    it { should transition_from(:awaiting_dispatch).to(:responded) }
    it { should require_permission(:can_respond?)
                  .using_options(user_id: responder.id)
                  .using_object(case_with_response) }
  end

  describe event(:close) do
    it { should transition_from(:responded).to(:closed) }
    it { should require_permission(:can_close_case?)
                  .using_options(user_id: manager.id)
                  .using_object(responded_case) }
  end

  describe 'trigger assign_responder!' do
    it 'triggers an assign_responder event' do
      expect do
        new_case.state_machine.assign_responder! manager,
                                                 managing_team,
                                                 responding_team
      end.to trigger_the_event(:assign_responder)
               .on_state_machine(new_case.state_machine)
               .with_parameters user_id:            manager.id,
                                managing_team_id:   managing_team.id,
                                responding_team_id: responding_team.id
    end
  end

  describe 'trigger flag_for_clearance!' do
    it 'triggers a flag_for_clearance event' do
      expect { assigned_case.state_machine.flag_for_clearance! manager }
        .to trigger_the_event(:flag_for_clearance)
              .on_state_machine(assigned_case.state_machine)
              .with_parameters(user_id: manager.id)
    end
  end

  describe 'trigger accept_responder_assignment!' do
    it 'triggers an accept_responder_assignment event' do
      expect do
        assigned_case.state_machine.accept_responder_assignment! responder,
                                                                 responding_team
      end.to trigger_the_event(:accept_responder_assignment)
               .on_state_machine(assigned_case.state_machine)
               .with_parameters(user_id: responder.id,
                                responding_team_id: responding_team.id)
    end
  end

  describe 'trigger reject_responder_assignment!' do
    let(:message) { |example| "test #{example.description}" }

    it 'triggers a reject_responder_assignment event' do
      expect do
        assigned_case.state_machine.reject_responder_assignment! responder,
                                                                 responding_team,
                                                                 message
      end.to trigger_the_event(:reject_responder_assignment)
               .on_state_machine(assigned_case.state_machine)
               .with_parameters(user_id: responder.id,
                                responding_team_id: responding_team.id,
                                message: message)
    end
  end

  describe 'trigger add_responses!' do
    let(:filenames) { ['file1.pdf', 'file2.pdf'] }

    it 'triggers an add_responses event' do
      expect do
        case_being_drafted.state_machine.add_responses! responder,
                                                        responding_team,
                                                        filenames
      end.to trigger_the_event(:add_responses)
               .on_state_machine(case_being_drafted.state_machine)
               .with_parameters(user_id: responder.id,
                                responding_team_id: responding_team.id,
                                filenames: filenames)
    end
  end

  describe 'trigger remove_response!' do
    let(:filenames) { ['file1.pdf'] }

    context 'no attachments left' do
      it 'triggers a remove_last_response event' do
        expect do
          case_with_response.state_machine.remove_response! responder,
                                                            responding_team,
                                                            filenames,
                                                            0
        end.to trigger_the_event(:remove_last_response)
                 .on_state_machine(case_with_response.state_machine)
                 .with_parameters(user_id: responder.id,
                                  responding_team_id: responding_team.id,
                                  filenames: filenames)
      end
    end

    context 'some attachments left' do
      it 'triggers a remove_last_response event' do
      expect do
        case_with_response.state_machine.remove_response!(
          responder,
          responding_team,
          filenames,
          1,
        )
      end.to trigger_the_event(:remove_response)
               .on_state_machine(case_with_response.state_machine)
               .with_parameters(user_id: responder.id,
                                responding_team_id: responding_team.id,
                                filenames: filenames)
      end
    end
  end

  describe 'trigger respond!' do
    it 'triggers a respond event' do
      expect do
        case_with_response.state_machine.respond! responder,
                                                  responding_team
      end.to trigger_the_event(:respond)
               .on_state_machine(case_with_response.state_machine)
               .with_parameters(user_id: responder.id,
                                responding_team_id: responding_team.id)
    end
  end

  describe 'trigger close!' do
    it 'triggers a close event' do
      expect do
        responded_case.state_machine.close! manager,
                                            managing_team
      end.to trigger_the_event(:close)
               .on_state_machine(responded_case.state_machine)
               .with_parameters(user_id: manager.id,
                                managing_team_id: managing_team.id)
    end
  end

  describe '.event_name' do
    context 'valid state machine event' do
      it 'returns human readable format' do
        expect(CaseStateMachine.event_name(:accept_responder_assignment)).to eq 'Accept responder assignment'
      end
    end

    context 'invalid state machine event' do
      it 'returns nil' do
        expect(CaseStateMachine.event_name(:trigger_article_50)).to be_nil
      end
    end
  end
end
