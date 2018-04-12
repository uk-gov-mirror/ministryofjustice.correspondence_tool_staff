require 'rails_helper'

RSpec.describe ActionNotificationsMailer, type: :mailer do
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
                 "To be accepted - FOI - #{assigned_case.number} - The anatomy of man",
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
                 "Pending clearance - FOI - #{pending_case.number} - The anatomy of man",
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

  describe 'notify_information_officers' do
    let(:approved_case)   { create :approved_case,
                                   name: 'Fyodor Ognievich Ilichion',
                                   received_date: 10.business_days.ago,
                                   subject: 'The anatomy of man' }
    let(:assignment)      { approved_case.responder_assignment }
    let(:responding_team) { assignment.team }
    let(:responder)       { responding_team.responders.first }
    let(:mail)            { described_class.notify_information_officers(approved_case, 'Ready to send')}

    it 'personalises the email' do
      allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
      expect(mail.govuk_notify_personalisation)
        .to eq({
         email_subject:
           "Ready to send - FOI - #{approved_case.number} - The anatomy of man",
         responder_full_name: assignment.user.full_name,
         case_current_state: 'ready to send',
         case_number: approved_case.number,
         case_abbr: 'FOI',
         case_name: 'Fyodor Ognievich Ilichion',
         case_received_date: 10.business_days.ago.to_date.strftime(Settings.default_date_format),
         case_subject: 'The anatomy of man',
         case_link: case_url(approved_case.id),
         case_draft_deadline: approved_case.internal_deadline.strftime(Settings.default_date_format),
         case_external_deadline: approved_case.external_deadline.strftime(Settings.default_date_format)
         })
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to include assignment.user.email
    end

    context 'ready to send' do
      let(:mail) { described_class.notify_information_officers(approved_case, 'Ready to send')}

      it 'sets the template' do
        expect(mail.govuk_notify_template)
          .to eq '46dc4848-5ad7-4772-9de4-dd6b6f558e5b'
      end
    end

    context 'redraft' do
      let(:mail) { described_class.notify_information_officers(approved_case, 'Redraft requested')}

      it 'sets the template' do
        expect(mail.govuk_notify_template)
          .to eq '534f0e07-007f-4a48-99e4-c46a41fbd81f'
      end

      it 'personalises the email' do
        allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
        expect(mail.govuk_notify_personalisation)
          .to include(email_subject: "Redraft requested - FOI - #{approved_case.number} - The anatomy of man")
      end
    end

    context 'message' do
      let(:mail) { described_class.notify_information_officers(approved_case, 'Message received')}

      it 'sets the template' do
        expect(mail.govuk_notify_template)
          .to eq '55d7abbc-9042-4646-8835-35a1b2e432c4'
      end

      it 'personalises the email' do
        allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
        expect(mail.govuk_notify_personalisation)
          .to include(email_subject: "Message received - FOI - #{approved_case.number} - The anatomy of man")
      end
    end
  end

  describe 'case_assigned_to_another_user' do
    let(:accepted_case)   { create :accepted_case,
                                   name: 'Fyodor Ognievich Ilichion',
                                   received_date: 10.business_days.ago,
                                   subject: 'The anatomy of man'}
    let(:responding_team) { accepted_case.responding_team }
    let(:responder)       { responding_team.responders.first }
    let(:mail)            { described_class
                                .case_assigned_to_another_user(accepted_case,
                                                               responder) }

    it 'sets the template' do
      expect(mail.govuk_notify_template)
        .to eq '1e26c707-e7e3-4b21-835d-1241da6ea251'
    end

    it 'personalises the email' do
      allow(CaseNumberCounter).to receive(:next_for_date).and_return(333)
      expect(mail.govuk_notify_personalisation)
        .to eq({
         email_subject:
           "Assigned to you - FOI - #{accepted_case.number} - The anatomy of man",
         user_name: responder.full_name,
         case_number: accepted_case.number,
         case_abbr: 'FOI',
         case_name: 'Fyodor Ognievich Ilichion',
         case_received_date: 10.business_days.ago.to_date.strftime(Settings.default_date_format),
         case_subject: 'The anatomy of man',
         case_link: case_url(accepted_case.id),
         case_external_deadline: accepted_case.external_deadline.strftime(Settings.default_date_format)
         })
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to include responder.email
    end
  end

  describe 'account_not_active' do
    let(:user) { create :user, full_name: 'Someone' }
    let(:mail) { described_class.account_not_active(user) }

    it 'sets the template' do
      expect(mail.govuk_notify_template)
          .to eq '2a7531a6-4976-4400-9478-0829d3f46cc9'
    end

    it 'personalises the email' do
      expect(mail.govuk_notify_personalisation)
          .to eq({
                     email_subject: 'Your CMS user account has been deactivated',
                     user_full_name: 'Someone',
                 })
    end

    it 'sets the To address of the email' do
      expect(mail.to).to include user.email
    end
  end
end
