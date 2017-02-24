require 'rails_helper'

feature 'uploaded files on case details view' do
  given(:drafter)  { create(:drafter) }
  given(:assigner) { create(:assigner) }
  given(:kase)     { create(:accepted_case, drafter: drafter) }

  background do
    login_as user
  end

  shared_examples 'uploaded attachments can be viewed' do
    given(:attached_response) do
      create(:case_response, case: kase)
    end
    given(:attachment_url) do
      URI.encode("#{CASE_UPLOADS_S3_BUCKET.url}/#{attached_response.key}")
    end
    given(:attachment_object) do
      instance_double(
        Aws::S3::Object,
        delete: instance_double(Aws::S3::Types::DeleteObjectOutput),
        public_url: attachment_url
      )
    end
    given(:uploaded_file) do
      cases_show_page.uploaded_files.files.first
    end

    background do
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                         .with(attached_response.key)
                                         .and_return(attachment_object)
    end

    scenario 'can be listed' do
      cases_show_page.load(id: kase.id)

      expect(cases_show_page).to have_uploaded_files
      expect(uploaded_file.filename).to have_content(attached_response.filename)
    end

    scenario 'can be downloaded' do
      cases_show_page.load(id: kase.id)

      expect {
        uploaded_file.download.click
      }.to redirect_to_external(attachment_url)
    end

    scenario 'can remove the response' do
      cases_show_page.load(id: kase.id)

      uploaded_file.remove.click
      expect(cases_show_page).not_to have_uploaded_files
      expect(attachment_object).to have_received(:delete)
      expect(current_path).to eq case_path(kase)
    end

    scenario 'can remove the response with JS', js: true do
      cases_show_page.load(id: kase.id)

      uploaded_file.remove.click
      cases_show_page.wait_until_uploaded_files_invisible
      expect(cases_show_page).not_to have_uploaded_files
      expect(attachment_object).to have_received(:delete)
    end

    scenario 'remove link is configured to request confirmation' do
      cases_show_page.load(id: kase.id)

      expect(uploaded_file.remove['data-confirm'])
        .to eq "Are you sure you want to remove #{attached_response.filename}?"
    end

    scenario 'removes the section from the page' do
      cases_show_page.load(id: kase.id)

      uploaded_file.remove.click
      cases_show_page.wait_until_uploaded_files_invisible
      expect(cases_show_page).not_to have_uploaded_files
    end

    scenario 'removes the section from the page with JS', js: true do
      cases_show_page.load(id: kase.id)

      uploaded_file.remove.click
      cases_show_page.wait_until_uploaded_files_invisible
      expect(cases_show_page).not_to have_uploaded_files
    end

    context 'case has multiple attachments' do
      before do
        create :case_response, case: kase
      end

      scenario 'uploaded files section is not removed' do
        cases_show_page.load(id: kase.id)

        uploaded_file.remove.click
        expect(cases_show_page).to have_uploaded_files
        expect(cases_show_page.uploaded_files.files.count).to eq 1
      end

      scenario 'uploaded files section is not removed with JS', js: true do
        cases_show_page.load(id: kase.id)

        uploaded_file.remove.click
        cases_show_page.uploaded_files.wait_for_files count: 1
      end
    end
  end

  context 'as the assigned drafter' do
    given(:user) { drafter }

    it_behaves_like 'uploaded attachments can be viewed'

    context 'with no attached responses' do
      scenario 'is not visible' do
        cases_show_page.load(id: kase.id)

        expect(cases_show_page).not_to have_uploaded_files
      end
    end
  end

  context 'as an assigner' do
    given(:user) { assigner }

    context 'with an attached response' do
      given(:attached_response) do
        create(:case_response, case: kase)
      end

      before do
        attached_response
      end

      scenario 'is not visible' do
        cases_show_page.load(id: kase.id)

        expect(cases_show_page).not_to have_uploaded_files
      end
    end
  end
end
