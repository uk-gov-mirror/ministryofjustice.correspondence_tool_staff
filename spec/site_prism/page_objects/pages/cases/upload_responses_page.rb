module PageObjects
  module Pages
    module Cases
      class UploadResponsesPage < PageObjects::Pages::Base
        include SitePrism::Support::DropInDropzone

        set_url '/cases/{id}/responses/new/upload_responses'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection,
                '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection,
                '.page-heading'

        section :clearance,
                PageObjects::Sections::Cases::ClearanceCopySection,
                '.clearance-copy'

        element :dropzone_container, '.dropzone'
        element :file_fields, '#uploaded_files'
        element :upload_response_button, '.button'
        element :response_action, '#response_action'

        # only shows up when using drop_in_dropzone
        element :uploaded_request_file_input, '#uploadedRequestFileInput'

        # Upload a file to Dropzone.js
        def drop_in_dropzone(file_path)
          super file_path: file_path,
                input_name: 'uploaded_files[]',
                container_selector: '.dropzone:first'
        end
      end
    end
  end
end
