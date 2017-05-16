class CaseDecorator < Draper::Decorator
  delegate_all

  def who_its_with
    case current_state
    when 'closed'    then ''
    when 'responded' then managing_team.name
    else
      responder_or_team
    end
  end

  def time_taken
    business_days = received_date.business_days_until(date_responded)
    I18n.t('common.case.time_taken_result', count: business_days)
  end

  def timeliness
    if within_external_deadline?
      I18n.t('common.case.answered_in_time')
    else
      I18n.t('common.case.answered_late')
    end
  end

  def internal_deadline
    object.requires_clearance? ? object.internal_deadline : nil
  end


  private

  def responder_or_team
    if !responding_team.present?
      managing_team.name
    elsif responder.present? &&
          h.current_user.responding_teams.include?(responding_team)
      responder.full_name
    else
      responding_team.name
    end
  end
end

