require 'rails_helper'

RSpec.describe CasesController, type: :controller do

  let(:all_cases)  { create_list(:case, 5)             }
  let(:assigner)   { create(:user)                     }
  let(:drafter)    { create(:user, roles: ['drafter']) }
  let(:first_case) { all_cases.first                   }
  let(:responded_case)  { create(:responded_case) }

  before { create(:category, :foi) }

  context "as an anonymous user" do
    describe 'GET index' do
      it "be redirected to signin if trying to list of questions" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'GET new' do
      it "be redirected to signin if trying to start a new case" do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'GET edit' do
      it "be redirected to signin if trying to show a specific case" do
        get :edit, params: { id: first_case }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'PATCH update' do
      it "be redirected to signin if trying to update a specific case" do
        patch :update, params: { id: first_case, case: { category_id: create(:category, :gq).id } }
        expect(response).to redirect_to(new_user_session_path)
        expect(Case.first.category.name).to eq 'Freedom of information request'
      end
    end

    describe 'PATCH close' do
      it "be redirected to signin if trying to close a case" do
        patch :close, params: { id: responded_case }
        expect(response).to redirect_to(new_user_session_path)
        expect(Case.first.current_state).to eq 'responded'
      end
    end

    describe 'GET search' do
      it "be redirected to signin if trying to search for a specific case" do
        name = first_case.name
        get :search, params: { search: name }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context "as an authenticated assigner" do

    before { sign_in assigner }

    describe 'GET index' do

      let(:unordered_cases) do
        [
          create(:case, received_date: Date.parse('17/11/2016'), subject: 'newer request 2', id: 2),
          create(:case, received_date: Date.parse('17/11/2016'), subject: 'newer request 1', id: 1),
          create(:case, received_date: Date.parse('16/11/2016'), subject: 'request 2', id: 3),
          create(:case, received_date: Date.parse('16/11/2016'), subject: 'request 1', id: 4),
          create(:case, received_date: Date.parse('15/11/2016'), subject: 'older request 2', id: 5),
          create(:case, received_date: Date.parse('15/11/2016'), subject: 'older request 1', id: 6)
        ]
      end

      before {
        get :index
      }

      it 'assigns @cases, sorted by external_deadline, then ID' do
        expect(assigns(:cases)).
          to eq unordered_cases.sort_by { |c| [c.external_deadline, c.id] }
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end
    end

    describe 'GET new' do
      before {
        get :new
      }

      it 'renders the new template' do
        expect(response).to render_template(:new)
      end
    end

    describe 'POST create' do
      context 'with valid params' do

        let(:params) do
          {
            case: {
              requester_type: 'member_of_the_public',
              name: 'A. Member of Public',
              postal_address: '102 Petty France',
              email: 'member@public.com',
              subject: 'FOI request from controller spec',
              message: 'FOI about prisons and probation',
              received_date_dd: Time.zone.today.day.to_s,
              received_date_mm: Time.zone.today.month.to_s,
              received_date_yyyy: Time.zone.today.year.to_s
            }
          }
        end

        let(:kase) { Case.first }

        it 'makes a DB entry' do
          expect { post :create, params: params }.
            to change { Case.count }.by 1
        end

        describe 'using the information supplied  ' do
          before { post :create, params: params }

          it 'for #requester_type' do
            expect(kase.requester_type).to eq 'member_of_the_public'
          end

          it 'for #name' do
            expect(kase.name).to eq 'A. Member of Public'
          end

          it 'for #postal_address' do
            expect(kase.postal_address).to eq '102 Petty France'
          end

          it 'for #email' do
            expect(kase.email).to eq 'member@public.com'
          end

          it 'for #subject' do
            expect(kase.subject).
              to eq 'FOI request from controller spec'
          end

          it 'for #message' do
            expect(kase.message).
              to eq 'FOI about prisons and probation'
          end

          it 'for #received_date' do
            expect(kase.received_date).to eq Time.zone.today
          end
        end
      end
    end

    describe 'GET edit' do

      before do
        get :edit, params: { id: first_case }
      end

      it 'assigns @case' do
        expect(assigns(:case)).to eq(Case.first)
      end

      it 'renders the edit template' do
        expect(response).to render_template(:edit)
      end
    end

    describe 'PATCH update' do

      it 'updates the case record' do
        patch :update, params: {
          id: first_case,
          case: { category_id: create(:category, :gq).id }
        }

        expect(Case.first.category.abbreviation).to eq 'GQ'
      end

      it 'does not overwrite entries with blanks (if the blank dropdown option is selected)' do
        patch :update, params: { id: first_case, case: { category: '' } }
        expect(Case.first.category.abbreviation).to eq 'FOI'
      end
    end

    describe 'PATCH close' do

      it "closes a case that has been responded to" do
        patch :close, params: { id: responded_case }
        expect(Case.first.current_state).to eq 'closed'
      end
    end

    describe 'GET search' do

      before do
        get :search, params: { search: first_case.name }
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end
    end
  end

  context 'as an authenticated drafter' do
    before { sign_in drafter }

    describe 'GET index' do

      let(:unordered_cases) do
        [
          create(:case, received_date: Date.parse('17/11/2016'), subject: 'newer request 2', id: 2),
          create(:case, received_date: Date.parse('17/11/2016'), subject: 'newer request 1', id: 1),
          create(:case, received_date: Date.parse('16/11/2016'), subject: 'request 2', id: 3),
          create(:case, received_date: Date.parse('16/11/2016'), subject: 'request 1', id: 4),
          create(:case, received_date: Date.parse('15/11/2016'), subject: 'older request 2', id: 5),
          create(:case, received_date: Date.parse('15/11/2016'), subject: 'older request 1', id: 6)
        ]
      end

      let(:drafters_workbasket) { Case.all.select {|kase| kase.drafter == drafter} }

      before {
        unordered_cases
        create(:assignment, assignee: drafter, case_id: 1)
        create(:assignment, assignee: drafter, case_id: 2)
        drafters_workbasket
        get :index
      }

      it 'assigns @cases, sorted by external_deadline, then ID' do
        expect(assigns(:cases)).
          to eq drafters_workbasket.sort_by { |c| [c.external_deadline, c.id] }
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end
    end

    describe 'GET new' do
      before {
        get :new
      }

      it 'does not render the new template' do
        expect(response).not_to render_template(:new)
      end

      it 'redirects to the application root path' do
        expect(response).to redirect_to(authenticated_root_path)
      end
    end

    describe 'POST create' do
      let(:kase) { build(:case, subject: 'Drafters cannot create cases') }

      let(:params) do
        {
          case: {
            requester_type: 'member_of_the_public',
            name: 'A. Member of Public',
            postal_address: '102 Petty France',
            email: 'member@public.com',
            subject: 'Drafters cannot create cases',
            message: 'I am a drafter attempting to create a case',
            received_date_dd: Time.zone.today.day.to_s,
            received_date_mm: Time.zone.today.month.to_s,
            received_date_yyyy: Time.zone.today.year.to_s
          }
        }
      end

      subject { post :create, params: params }

      it 'does not create a new case' do
        expect{ subject }.not_to change { Case.count }
      end

      it 'redirects to the application root path' do
        expect(subject).to redirect_to(authenticated_root_path)
      end

      describe 'PATCH close' do
        it "does not close a case that has been responded to" do
          patch :close, params: { id: responded_case }
          expect(Case.first.current_state).not_to eq 'closed'
        end

        it 'redirects to the application root path' do
          expect(subject).to redirect_to(authenticated_root_path)
        end
      end
    end
  end

  # An astute reader who has persevered to this point in the file may notice
  # that the following tests are in a different structure than those above:
  # above, the top-most grouping is a context describing authentication, with
  # what action is being tested (GET new, POST create, etc) sub-grouped within
  # those contexts. This breaks up the tests for, say, GET new so that to read
  # how that action/functionality behaves becomes hard. The tests below seek to
  # remedy this by modelling how they could be grouped by functionality
  # primarily, with sub-grouping for different contexts.
  describe 'GET new_response_upload' do
    context 'as an anonymous user' do
      describe 'GET new_response_upload' do
        it 'redirects to signin' do
          get :new_response_upload, params: { id: first_case }
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'as an authenticated assigner' do
      before { sign_in assigner }

      xit 'redirects to signin' do
        get :new_response_upload, params: { id: first_case }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated drafter' do
      before { sign_in drafter }

      it 'assigns @case' do
        get :new_response_upload, params: { id: first_case }
        expect(assigns(:case)).to eq(Case.first)
      end

      it 'renders the new_response_upload view' do
        get :new_response_upload, params: { id: first_case }
        expect(response).to have_rendered(:new_response_upload)
      end
    end
  end

  describe 'POST upload_responses' do
    let(:attachment_url) do
      'https://correspondence-staff-uploads.s3.amazonaws.com' +
        '/356a192b7913b04c54574d18c28d46e6395428ab/responses/test file.jpg'
    end

    let(:do_upload_responses) do
      post :upload_responses, params: {
             id:             first_case,
             type:           'response',
             attachment_url: [attachment_url]
           }
    end

    context 'as an anonymous user' do
      it 'redirects to signin' do
        expect do
          do_upload_responses
        end.not_to change { first_case.attachments.count }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated assigner' do
      before { sign_in assigner }

      xit 'redirects to signin' do
        expect do
          do_upload_responses
        end.not_to change { first_case.attachments.count }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated drafter' do
      before { sign_in drafter }

      it 'creates a new case attachment' do
        expect { do_upload_responses }.
          to change { first_case.reload.attachments.count }
      end

      it 'URI encodes the attachment url' do
        do_upload_responses
        expect(first_case.attachments.first.url).to eq URI.encode attachment_url
      end

      it 'test the type field' do
        do_upload_responses
        expect(first_case.attachments.first.type).to eq 'response'
      end

      it 'redirects to the case detail page' do
        do_upload_responses
        expect(response).to redirect_to(case_path(first_case))
      end

      context 'uploading invalid attachment type' do
        let(:attachment_url) { 'https://correspondence-staff-case-uploads-testing.s3-eu-west-1.amazonaws.com/356a192b7913b04c54574d18c28d46e6395428ab/responses/invalid_type.exe' }

        it 'renders the new_response_upload page' do
          do_upload_responses
          expect(response).to have_rendered(:new_response_upload)
        end

        it 'does not create a new case attachment' do
          expect { do_upload_responses }.
            to_not change { first_case.reload.attachments.count }
        end

        xit 'removes the attachment from S3'
      end

      context 'uploading attachment that are too large' do
        xit 'renders the new_response_upload page' do
          do_upload_responses
          expect(response).to have_rendered(:new_response_upload)
        end

        xit 'does not create a new case attachment' do
          expect { do_upload_responses }.
            to_not change { first_case.reload.attachments.count }
        end

        xit 'removes the attachment from S3'
      end
    end
  end
end
