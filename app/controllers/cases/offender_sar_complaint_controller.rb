module Cases
  class OffenderSarComplaintController < OffenderSarController
    def initialize
      @correspondence_type = CorrespondenceType.offender_sar_complaint
      @correspondence_type_key = 'offender_sar_complaint'

      super
    end

    def new
      permitted_correspondence_types
      authorize case_type, :can_add_case?

      @case = build_case_from_session(Case::SAR::OffenderComplaint)
      @case.current_step = params[:step]
    end

    def set_case_types
      @case_types = ["Case::SAR::OffenderComplaint"]
    end

    def case_type
      Case::SAR::OffenderComplaint
    end

  end
end
