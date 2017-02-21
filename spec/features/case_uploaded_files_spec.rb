require 'rails_helper'

feature 'uploaded files on case details view' do
  given(:case_details_page) { CaseDetailsPage.new }
  given(:drafter) { create(:drafter) }
  given(:kase)    { create(:accepted_case, drafter: drafter) }
  background do
    login_as user
  end

  context 'as the assigned drafter' do
    given(:user) { drafter }

    context 'with an attached response' do
      given(:attached_response) do
        create(:case_response, case: kase)
      end
      given(:attachment_path) { URI.parse(attached_response.url).path[1..-1] }
      given(:attachment_object) do
        instance_double(
          Aws::S3::Object,
          delete: instance_double(Aws::S3::Types::DeleteObjectOutput)
        )
      end

      background do
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                           .with(attachment_path)
                                           .and_return(attachment_object)
        attached_response
      end

      scenario 'can be listed' do
        case_details_page.load(id: kase.id)

        expect(case_details_page).to have_uploaded_files
        expect(case_details_page.uploaded_files.files.first.filename)
          .to have_content(attached_response.filename)
      end

      scenario 'can be downloaded' do
        case_details_page.load(id: kase.id)

        expect {
          case_details_page.uploaded_files.files.first.download.click
        }.to redirect_to_external(attached_response.url)
      end

      scenario 'can remove the response' do
        case_details_page.load(id: kase.id)

        case_details_page.uploaded_files.files.first.remove.click
        expect(case_details_page).not_to have_uploaded_files
        expect(attachment_object).to have_received(:delete)
        expect(current_path).to eq case_path(kase)
      end

      scenario 'can remove the response with JS', js: true do
        case_details_page.load(id: kase.id)

        case_details_page.uploaded_files.files.first.remove.click
        case_details_page.uploaded_files.wait_until_files_invisible
        expect(case_details_page.uploaded_files).not_to have_files
        expect(attachment_object).to have_received(:delete)
      end
    end

    context 'with no attached responses' do
      scenario 'is not visible' do
        case_details_page.load(id: kase.id)

        expect(case_details_page).not_to have_uploaded_files
      end
    end
  end
end
