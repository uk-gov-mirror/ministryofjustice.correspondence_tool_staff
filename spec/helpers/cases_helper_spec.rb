require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the CasesHelper. For example:
#
# describe CasesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe CasesHelper, type: :helper do

  let(:manager)   { create :manager }
  let(:responder) { create :responder }
  let(:coworker)  { create :responder,
                           responding_teams: responder.responding_teams }
  let(:another_responder) { create :responder }

  describe '#action_button_for(event)' do

    context 'when event == :assign_responder' do
      it 'generates HTML that links to the new assignment page' do
        @case = create(:case)
        expect(action_button_for(:assign_responder)).to eq(
          "<a id=\"action--assign-to-responder\" class=\"button\" href=\"/cases/#{@case.id}/assignments/new\">Assign to a responder</a>")
      end
    end

    context 'when event == :close' do
      it 'generates HTML that links to the close case action' do
        @case = create(:responded_case)
        expect(action_button_for(:close)).to eq(
"<a id=\"action--close-case\" class=\"button\" data-method=\"get\" \
href=\"/cases/#{@case.id}/close\">Close case</a>"
          )
      end
    end

    context 'when event == :add_responses' do
      context 'case does not require clearance' do
        it 'generates HTML that links to the upload response page' do
          @case = create(:accepted_case)
          expect(@case).to receive(:requires_clearance?).and_return(false)
          expect(action_button_for(:add_responses)).to eq(
             "<a id=\"action--upload-response\" class=\"button\" href=\"/cases/#{@case.id}/new_response_upload?mode=upload\">Upload response</a>"
            )
        end
      end

      context 'case requires clearance' do
        it 'generates HTML that links to the upload response page' do
          @case = create(:accepted_case)
          expect(@case).to receive(:requires_clearance?).and_return(true)
          expect(action_button_for(:add_responses)).to eq(
           "<a id=\"action--upload-response\" class=\"button\" href=\"/cases/#{@case.id}/new_response_upload?mode=upload-flagged\">Upload response</a>"
         )
        end
      end

    end

    context 'when event = :respond' do
      it 'generates HTML that links to the upload response page' do
        @case = create(:case_with_response)
        expect(action_button_for(:respond)).to eq(
"<a id=\"action--mark-response-as-sent\" class=\"button\" \
href=\"/cases/#{@case.id}/respond\">Mark response as sent</a>"
          )
      end
    end

    context 'when event = :request_amends' do
      it 'generates an HTML link to cases/request_amends' do
        @case = create(:case)
        expect(action_button_for(:request_amends))
          .to eq "<a id=\"action--request-amends\" " +
                 "class=\"button\" " +
                 "href=\"/cases/#{@case.id}/request_amends\">" +
                 "Request amends</a>"
      end
    end

    context 'when event == :reassign_user' do
      it 'generates HTML that links to the close case action' do
        @case = create(:accepted_case)
        @assignment = @case.responder_assignment
        expect(action_button_for(:reassign_user)).to eq(
          "<a id=\"action--reassign-case\" class=\"button\" href=\"/cases/#{@case.id}/assignments/#{@assignment.id}/reassign_user\">Change team member</a>"
        )
      end
    end

  end

  describe '#case_uploaded_request_files_class' do
    before do
      @case = create(:case)
    end

    it 'returns nil when case has no errors on uploaded_request_files' do
      expect(case_uploaded_request_files_class).to be_nil
    end

    it 'returns error class when case has errors on uploaded_request_files' do
      @case.errors.add(:uploaded_request_files, :blank)
      expect(case_uploaded_request_files_class).to eq 'error'
    end
  end

  describe '#case_uploaded_request_files_id' do
    before do
      @case = create(:case)
    end

    it 'returns nil when case has no errors on uploaded_request_files' do
      expect(case_uploaded_request_files_id).to be_nil
    end

    it 'returns error id when case has errors on uploaded_request_files' do
      @case.errors.add(:uploaded_request_files, :blank)
      expect(case_uploaded_request_files_id)
        .to eq 'error_case_uploaded_request_files'
    end
  end
  describe '#show_remove_clearance_link' do
    context 'clearance can be removed' do
      it 'returns the remove clearance link' do
        dacu_flagged_kase = create :pending_dacu_clearance_case
        expect(show_remove_clearance_link(dacu_flagged_kase)).to eq("<a href=\"/cases/#{dacu_flagged_kase.id}/remove_clearance\">Remove clearance</a>")
      end
    end
    context 'clearance cannot be removed' do
      it 'returns an empty string' do
        press_flagged_case = create :pending_dacu_clearance_case_flagged_for_press
        expect(show_remove_clearance_link(press_flagged_case)).to eq ""
      end
    end
  end
end
