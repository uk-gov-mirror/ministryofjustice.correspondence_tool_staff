class CurrentTeamAndUserService

  attr_reader :team, :user

  def initialize(kase)
    @case = kase
    @dts = DefaultTeamService.new(@case)
    analyse_case
  end

  private

  def analyse_case
    case @case.current_state
    when 'unassigned'
      @team = @case.managing_team
      @user = nil
    when 'awaiting_responder'
      @team = @case.responding_team
      @user = nil
    when 'drafting', 'awaiting_dispatch'
      @team = @case.responding_team
      @user = @case.responder
    when 'pending_dacu_clearance'
      @team = @dts.approving_team
      @user = @case.approver_assignments.for_team(@team).first.user
    when 'responded'
      @team = @case.managing_team
      @user = nil
    when 'closed'
      @team = nil
      @user = nil
    else
      raise "State #{@case.current_state} unknown to CurrentTeamAndUserService"
    end
  end
end


