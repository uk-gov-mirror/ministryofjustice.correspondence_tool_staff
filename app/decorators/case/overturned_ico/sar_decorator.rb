class Case::OverturnedICO::SARDecorator < Case::OverturnedICO::BaseDecorator

  def pretty_type
    'ICO overturned (SAR)'
  end

  def requester_name_and_type
    pretty_type
  end

  def missing_info
    if object.closed?
      object.refusal_reason&.abbreviation == 'tmm' ? 'yes' : 'no'
    end
  end
end
