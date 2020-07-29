require "rails_helper"

describe Case::SAR::OffenderDecorator do
  let(:offender_sar_case) {create(:offender_sar_case).decorate }

  it 'instantiates the correct decorator' do
    expect(Case::SAR::Offender.new.decorate).to be_instance_of Case::SAR::OffenderDecorator
  end

  describe "#current_step" do
    it "returns the first step by default" do
      expect(offender_sar_case.current_step).to eq "subject-details"
    end
  end

  describe "#next_step" do
    it "causes #current_step to return the next step" do
      offender_sar_case.next_step

      expect(offender_sar_case.current_step).to eq "requester-details"
    end
  end

  describe "#get_step_partial" do
    it "returns the first step as default filename" do
      expect(offender_sar_case.get_step_partial).to eq "subject_details_step"
    end

    it "returns each subsequent step as a partial filename" do
      expect(offender_sar_case.get_step_partial).to eq "subject_details_step"
      offender_sar_case.next_step
      expect(offender_sar_case.get_step_partial).to eq "requester_details_step"
      offender_sar_case.next_step
      expect(offender_sar_case.get_step_partial).to eq "recipient_details_step"
      offender_sar_case.next_step
      expect(offender_sar_case.get_step_partial).to eq "requested_info_step"
      offender_sar_case.next_step
      expect(offender_sar_case.get_step_partial).to eq "request_details_step"
      offender_sar_case.next_step
      expect(offender_sar_case.get_step_partial).to eq "date_received_step"
    end
  end

end
