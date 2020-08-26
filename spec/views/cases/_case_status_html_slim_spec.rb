require 'rails_helper'

describe 'cases/case_status.html.slim', type: :view do

  it 'displays the all 4 key information ' do
    unassigned_case = double Case::BaseDecorator,
      status: "Needs reassigning",
      ico?: false,
      internal_deadline: DateTime.now.strftime(Settings.default_date_format),
      external_deadline: (DateTime.now + 10.days).strftime(Settings.default_date_format),
      current_state: 'drafting',
      type_abbreviation: 'FOI',
      who_its_with: 'DACU',
      offender_sar?: false


    render partial: 'cases/case_status.html.slim',
           locals:{ case_details: unassigned_case}

    partial = case_status_section(rendered)

    expect(partial.details.copy_label.text).to eq "Status"
    expect(partial.details.copy.text).to eq unassigned_case.status
    expect(partial.details.who_its_with_label.text).to eq "With"
    expect(partial.details.who_its_with.text)
        .to eq unassigned_case.who_its_with

    expect(partial.deadlines.draft_label.text).to eq 'Draft deadline'
    expect(partial.deadlines.draft.text)
        .to eq unassigned_case.internal_deadline
    expect(partial.deadlines.final_label.text).to eq 'Final deadline'
    expect(partial.deadlines.final.text)
        .to eq unassigned_case.external_deadline
  end


  it 'does not display "Who its with" for closed cases' do
    closed_case = double Case::BaseDecorator,
      status: "Closed",
      ico?: false,
      internal_deadline: DateTime.now.strftime(Settings.default_date_format) ,
      external_deadline: (DateTime.now + 10.days).strftime(Settings.default_date_format),
      current_state: 'closed',
      type_abbreviation: 'FOI',
      who_its_with: '',
      offender_sar?: false

    render partial: 'cases/case_status.html.slim',
           locals:{ case_details: closed_case}

    partial = case_status_section(rendered)

    expect(partial.details.copy.text).to eq closed_case.status
    expect(partial.details).to have_no_who_its_with

    expect(partial.deadlines.draft.text)
        .to eq closed_case.internal_deadline
    expect(partial.deadlines.final.text)
        .to eq closed_case.external_deadline
  end

  it 'does not display Draft deadline for non-trigger cases' do
    non_trigger_case = double Case::BaseDecorator,
      status: "Needs reassigning",
      external_deadline: (DateTime.now + 10.days).strftime(Settings.default_date_format),
      ico?: false,
      internal_deadline: nil,
      current_state: 'drafting',
      type_abbreviation: 'FOI',
      who_its_with: 'DACU',
      offender_sar?: false

    render partial: 'cases/case_status.html.slim',
           locals:{ case_details: non_trigger_case}

    partial = case_status_section(rendered)

    expect(partial.details.copy.text).to eq non_trigger_case.status
    expect(partial.details.who_its_with.text)
        .to eq non_trigger_case.who_its_with

    expect(partial.deadlines).to have_no_draft
    expect(partial.deadlines.final.text)
        .to eq non_trigger_case.external_deadline
  end

  context 'ICO case reference number' do
    it 'does not show ICO case reference number for foi cases' do
      non_trigger_case = double Case::BaseDecorator,
        status: "Needs reassigning",
        external_deadline: (DateTime.now + 10.days).strftime(Settings.default_date_format),
        ico?: false,
        internal_deadline: nil,
        current_state: 'drafting',
        type_abbreviation: 'FOI',
        who_its_with: 'DACU',
        offender_sar?: false

      render partial: 'cases/case_status.html.slim',
             locals:{ case_details: non_trigger_case}

      partial = case_status_section(rendered)

      expect(partial.details.copy.text).to eq non_trigger_case.status
      expect(partial.details.who_its_with.text)
          .to eq non_trigger_case.who_its_with

      expect(partial.deadlines).to have_no_draft
      expect(partial.deadlines.final.text)
          .to eq non_trigger_case.external_deadline

      expect(partial.details).to have_no_ico_ref_number_label
      expect(partial.details).to have_no_ico_ref_number
    end

    it 'displays ICO case reference number for ico appeal cases' do
      ico_case = double Case::ICO::BaseDecorator,
        status: "Needs reassigning",
        external_deadline: (DateTime.now + 10.days).strftime(Settings.default_date_format),
        ico_reference_number: '123456789ABC',
        ico?: true,
        internal_deadline: nil,
        current_state: 'drafting',
        type_abbreviation: 'ICO',
        who_its_with: 'DACU',
        offender_sar?: false


      render partial: 'cases/case_status.html.slim',
             locals:{ case_details: ico_case}

      partial = case_status_section(rendered)

      expect(partial.details.copy.text).to eq ico_case.status
      expect(partial.details.who_its_with.text)
          .to eq ico_case.who_its_with

      expect(partial.deadlines).to have_no_draft
      expect(partial.deadlines.final.text)
          .to eq ico_case.external_deadline

      expect(partial.details.ico_ref_number_label.text).to eq 'ICO case reference number'
      expect(partial.details.ico_ref_number.text).to eq ico_case.ico_reference_number

    end

    it 'displays the page counts for Offender Sar case' do
      offender_sar_case = double Case::SAR::OffenderDecorator,
        status: "Needs reassigning",
        external_deadline: (DateTime.now + 10.days).strftime(Settings.default_date_format),
        ico?: false,
        internal_deadline: nil,
        current_state: 'drafting',
        type_abbreviation: 'ICO',
        who_its_with: 'Branston Registry',
        offender_sar?: true,
        page_count: '500',
        number_exempt_pages: '200',
        number_final_pages: '250'


      render partial: 'cases/case_status.html.slim',
             locals:{ case_details: offender_sar_case}

      partial = case_status_section(rendered)

      expect(partial.details.page_counts.received_label.text).to eq 'Pages received'
      expect(partial.details.page_counts.received_number.text).to eq '500'
      expect(partial.details.page_counts.exempt_label.text).to eq 'Exempt pages'
      expect(partial.details.page_counts.exempt_number.text).to eq '200'
      expect(partial.details.page_counts.dispatched_label.text).to eq 'Pages for dispatch'
      expect(partial.details.page_counts.dispatched_number.text).to eq '250'

    end

    it 'does not display Page counts for non-offender SAR case' do
      ico_case = double Case::ICO::BaseDecorator,
        status: "Needs reassigning",
        external_deadline: (DateTime.now + 10.days).strftime(Settings.default_date_format),
        ico_reference_number: '123456789ABC',
        ico?: true,
        internal_deadline: nil,
        current_state: 'drafting',
        type_abbreviation: 'ICO',
        who_its_with: 'DACU',
        offender_sar?: false


      render partial: 'cases/case_status.html.slim',
             locals:{ case_details: ico_case}

      partial = case_status_section(rendered)

      expect(partial.details).to have_no_page_counts
    end

    let(:ico_overturned_sar) {
      double Case::OverturnedICO::SARDecorator,
        status: "Needs reassigning",
        external_deadline: (DateTime.now + 10.days).strftime(Settings.default_date_format),
        ico_reference_number: '123456789ABC',
        ico?: true,
        internal_deadline: nil,
        current_state: 'drafting',
        type_abbreviation: 'OVERTURNED_SAR',
        who_its_with: 'DACU',
        offender_sar?: false
    }

    it 'displays ICO case reference number for ICO overturned SAR cases' do
      render partial: 'cases/case_status.html.slim',
             locals: { case_details: ico_overturned_sar }
      partial = case_status_section(rendered)

      expect(partial.details.ico_ref_number_label.text)
        .to eq 'ICO case reference number'
      expect(partial.details.ico_ref_number.text).to eq '123456789ABC'
    end
  end

end
