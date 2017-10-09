require 'rails_helper'

RSpec.describe AssignmentMailer, type: :mailer do
  describe 'new_assignment' do
    let(:assigned_case)   { create :assigned_case,
                                   name: 'Fyodor Ognievich Ilichion',
                                   received_date: 10.business_days.ago,
                                   subject: 'The anatomy of man' }
    let(:assignment)      { assigned_case.responder_assignment }
    let(:responding_team) { assignment.team }
    let(:responder)       { responding_team.responders.first }
    let(:mail)            { described_class.new_assignment(assignment,
                                                           responder.email) }

    it 'sets the template' do
      expect(mail.govuk_notify_template)
        .to eq '6f4d8e34-96cb-482c-9428-a5c1d5efa519'
    end

    it 'personalises the email' do
      allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
      expect(mail.govuk_notify_personalisation)
        .to eq({
                 email_subject:
                   "#{assigned_case.number} - FOI - The anatomy of man - To be accepted",
                 team_name: assignment.team.name,
                 case_current_state: 'to be accepted',
                 case_number: assigned_case.number,
                 case_abbr: 'FOI',
                 case_name: 'Fyodor Ognievich Ilichion',
                 case_received_date: 10.business_days.ago.to_date.strftime(Settings.default_date_format),
                 case_subject: 'The anatomy of man',
                 case_link: edit_case_assignment_url(assigned_case.id, assignment.id)
               })
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to include responder.email
    end
  end

  describe 'ready_for_approver_review' do
    let(:pending_case)   { create :pending_press_clearance_case,
                                   name: 'Fyodor Ognievich Ilichion',
                                   received_date: 10.business_days.ago,
                                   subject: 'The anatomy of man' }
    let(:assignment)      { pending_case.approver_assignments.for_team(BusinessUnit.press_office).singular}
    let(:approving_team)  { assignment.team }
    let(:approver)        { assignment.user }
    let(:mail)            { described_class.ready_for_approver_review(assignment) }

    it 'sets the template' do
      expect(mail.govuk_notify_template)
        .to eq 'fe9a1e2a-2707-4e10-bb63-aae142f10382'
    end

    it 'personalises the email' do
      allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
      expect(mail.govuk_notify_personalisation)
        .to eq({
                 email_subject:
                   "#{pending_case.number} - FOI - The anatomy of man - Pending clearance",
                 approver_full_name: approver.full_name,
                 case_number: pending_case.number,
                 case_subject: 'The anatomy of man',
                 case_type: 'FOI',
                 case_name: 'Fyodor Ognievich Ilichion',
                 case_received_date: 10.business_days.ago.to_date.strftime(Settings.default_date_format),
                 case_external_deadline: pending_case.external_deadline.strftime(Settings.default_date_format),
                 case_link: case_url(pending_case.id)
               })
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to include approver.email
    end
  end
end
