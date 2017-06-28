# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  category_id          :integer
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#  received_by          :enum
#

FactoryGirl.define do

  factory :case do
    transient do
      identifier "new case"
      managing_team { find_or_create :team_dacu }
    end

    requester_type 'member_of_the_public'
    sequence(:name) { |n| "#{identifier} name #{n}" }
    email { Faker::Internet.email(identifier) }
    # association :category, factory: :category, strategy: :create
    category
    received_by 'email' #TODO Need to switch this between email or postal
    sequence(:subject) { |n| "#{identifier} subject #{n}" }
    sequence(:message) { |n| "#{identifier} message #{n}" }
    received_date { Time.zone.today.to_s }
    sequence(:postal_address) { |n| "#{identifier} postal address #{n}" }

    after(:build) do |_kase, evaluator|
      evaluator.managing_team
    end

    factory :awaiting_responder_case, parent: :case,
                                      aliases: [:assigned_case] do
      transient do
        identifier "assigned case"
        manager         { managing_team.managers.first }
        responding_team { create :responding_team }
      end

      after(:create) do |kase, evaluator|
        create :assignment,
               case: kase,
               team: evaluator.responding_team,
               state: 'pending',
               role: 'responding'
        create :case_transition_assign_responder,
               case: kase,
               user: evaluator.manager,
               managing_team: evaluator.managing_team,
               responding_team: evaluator.responding_team
        kase.reload
      end
    end

    factory :accepted_case, parent: :assigned_case,
                            aliases: [:case_being_drafted] do
      transient do
        identifier "accepted case"
        responder { create :responder }
        responding_team { responder.responding_teams.first }
      end

      after(:create) do |kase, evaluator|
        kase.responder_assignment.update_attribute :user, evaluator.responder
        kase.responder_assignment.accepted!
        create :case_transition_accept_responder_assignment,
               case: kase,
               user_id: kase.responder.id,
               responding_team_id: kase.responding_team.id
        kase.reload
      end
    end

    factory :rejected_case, parent: :assigned_case do
      transient do
        rejection_message { Faker::Hipster.sentence }
        responder         { create :responder }
        responding_team   { responder.responding_teams.first }
        identifier        "rejected case"
      end

      after(:create) do |kase, evaluator|
        kase.responder_assignment.reasons_for_rejection =
          evaluator.rejection_message
        kase.responder_assignment.rejected!
        create :case_transition_reject_responder_assignment,
               case: kase,
               user: evaluator.responder,
               responding_team: evaluator.responding_team,
               message: evaluator.rejection_message
        kase.reload
      end
    end

    factory :case_with_response, parent: :accepted_case do
      transient do
        identifier "case with response"
        responder { create :responder, full_name: 'Ivor Response' }
        responses { [build(:correspondence_response, type: 'response', user_id: responder.id)] }
      end

      after(:create) do |kase, evaluator|
        kase.attachments.push(*evaluator.responses)

        create :case_transition_add_responses,
               case_id: kase.id,
               responding_team_id: evaluator.responding_team.id,
               user_id: evaluator.responder.id
               # filenames: [evaluator.attachment.filename]
        kase.reload
      end
    end

    factory :pending_dacu_clearance_case, parent: :case_with_response do
      transient do
        approving_team { find_or_create :team_dacu_disclosure }
        approver { create :disclosure_specialist }
      end

      after(:create) do |kase, evaluator|
        create :approver_assignment,
                 case: kase,
                 team: evaluator.approving_team,
                 state: 'accepted',
                 user_id: evaluator.approver.id

        create :case_transition_pending_dacu_clearance,
               case_id: kase.id,
               user_id: evaluator.responder.id
        kase.reload
      end

    end

    factory :approved_case, parent: :pending_dacu_clearance_case do
      transient do
        approving_team { find_or_create :team_dacu_disclosure }
        approver { create :disclosure_specialist }
      end

      after(:create) do |kase, evaluator|
        create :case_transition_approve,
               case: kase,
               approving_team: evaluator.approving_team,
               user: evaluator.approver

        kase.approver_assignments.each { |a| a.update approved: true }
        kase.reload
      end

    end

    factory :responded_case, parent: :case_with_response do
      transient do
        identifier "responded case"
        responder { User.find_by_full_name('Ivor Response') || create(:responder, full_name: 'Ivor Response') }
      end

      date_responded Date.today

      after(:create) do |kase, evaluator|
        create :case_transition_respond,
               case: kase,
               user_id: evaluator.responder.id,
               responding_team_id: evaluator.responding_team.id
        kase.reload
      end
    end

    factory :closed_case, parent: :responded_case do
      transient do
        identifier "closed case"
      end

      received_date { 22.business_days.ago }
      date_responded { 4.business_days.ago }
      outcome { CaseClosure::Outcome.first || create(:outcome) }

      after(:create) do |kase, evaluator|
        create :case_transition_close,
               case: kase,
               user: evaluator.manager,
               managing_team: evaluator.managing_team,
               responding_team: evaluator.responding_team
        kase.reload
      end

      trait :requires_exemption do
        outcome { create :outcome, :requires_refusal_reason }
        refusal_reason { create(:refusal_reason, :requires_exemption) }
        exemptions { [ create(:exemption) ] }
      end

      trait :without_exemption do
        outcome { create :outcome, :requires_refusal_reason }
        refusal_reason { create(:refusal_reason) }
      end

      trait :with_ncnd_exemption do
        outcome { create :outcome, :requires_refusal_reason }
        refusal_reason { create(:refusal_reason, :requires_exemption) }
        exemptions { [create(:exemption, :ncnd), create(:exemption)] }
      end

      trait :without_ncnd_exemption do
        outcome { create :outcome, :requires_refusal_reason }
        refusal_reason { create(:refusal_reason, :requires_exemption) }
        exemptions { [create(:exemption), create(:exemption)] }
      end

      trait :late do
        received_date 30.business_days.ago
        date_responded 1.business_day.ago
      end
    end
  end

  trait :flagged do
    transient do
      approving_team { create :approving_team }
    end

    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.approving_team,
             state: 'pending'
      kase.reload
    end
  end

  trait :flagged_accepted do
    transient do
      approver { create :approver }
      approving_team { approver.approving_team }
    end

    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             user: evaluator.approver,
             team: evaluator.approving_team,
             state: 'accepted'
    end
  end

  trait :dacu_disclosure do
    # Use with :flagged or :flagged_accepted trait
    transient do
      approver { create :disclosure_specialist }
      approving_team { find_or_create :team_dacu_disclosure }
    end
  end

  trait :press_office do
    # Use with :flagged or :flagged_accepted trait
    transient do
      approver { create :press_officer }
      approving_team { find_or_create :team_press_office }
    end
  end
end
