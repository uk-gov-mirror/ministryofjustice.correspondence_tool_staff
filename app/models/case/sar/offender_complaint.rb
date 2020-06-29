class Case::SAR::OffenderComplaint < Case::SAR::Offender

  GOV_UK_DATE_FIELDS = %i[
    date_of_birth
    date_responded
    date_draft_compliant
    external_deadline
    received_date
  ].freeze

  acts_as_gov_uk_date(*GOV_UK_DATE_FIELDS)

  jsonb_accessor :properties,
                 date_of_birth: :date,
                 escalation_deadline: :date,
                 external_deadline: :date,
                 flag_as_high_profile: :boolean,
                 internal_deadline: :date,
                 other_subject_ids: :string,
                 previous_case_numbers: :string,
                 prison_number: :string,
                 reply_method: :string,
                 subject_aliases: :string,
                 subject_full_name: :string,
                 subject_type: :string,
                 third_party_relationship: :string,
                 third_party: :boolean,
                 third_party_reference: :string,
                 third_party_company_name: :string,
                 late_team_id: :integer

end
