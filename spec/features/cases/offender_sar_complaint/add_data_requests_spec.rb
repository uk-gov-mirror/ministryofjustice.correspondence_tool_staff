require 'rails_helper'

feature 'Data Requests for an Offender SAR complaint' do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_complaint) { create(:offender_sar_complaint).decorate }

  background do
    login_as manager
  end

  scenario 'successfully add 2 new requests', js: true do
    cases_show_page.load(id: offender_sar_complaint.id)

    expect(cases_show_page).to_not have_content "Record data request"
    expect(cases_show_page).to_not have_content "Update exempt pages"
    expect(cases_show_page).to_not have_content "Update final page count"

    click_on 'Requires data'

    expect(cases_show_page).to have_content "Record data request"
    expect(cases_show_page).to have_content "Update exempt pages"
    expect(cases_show_page).to have_content "Update final page count"

    click_on 'Record data request'
    expect(data_request_page).to be_displayed

    request_values = {
      location: 'HMP Leicester  ',
      request_type: 'all_prison_records',
      request_type_note: 'Lorem ipsum',
      date_requested: Date.new(2020, 8, 15),
      date_from: Date.new(2018, 8, 15),
      date_to: Date.new(2019, 8, 15),
    }

    data_request_page.form.location.fill_in(with: request_values[:location])
    data_request_page.form.choose_request_type(request_values[:request_type])
    data_request_page.form.set_date_requested(request_values[:date_requested])
    data_request_page.form.set_date_from(request_values[:date_from])
    data_request_page.form.set_date_to(request_values[:date_to])

    click_on 'Continue'

    record = DataRequest.last
    expect(record.location).to eq 'HMP Leicester'
    expect(record.request_type).to eq 'all_prison_records'
    expect(record.request_type_note).to eq ''
    expect(record.date_from).to eq Date.new(2018, 8, 15)
    expect(record.date_to).to eq Date.new(2019, 8, 15)

    expect(cases_show_page).to be_displayed
    data_requests = cases_show_page.data_requests.rows
    expect(data_requests.size).to eq 1

    row = cases_show_page.data_requests.rows[0]
    expect(row.location).to have_text request_values[:location].strip
    expect(row.request_type).to have_text request_values[:request_type].strip.humanize
    expect(row.date_requested).to have_text '15 Aug 2020'
    expect(row.pages).to have_text '0'

    click_on 'Record data request'
    data_request_page.form.location.fill_in(with: request_values[:location])
    data_request_page.form.choose_request_type('other')
    data_request_page.form.request_type_note.fill_in(with: request_values[:request_type_note])
    data_request_page.form.set_date_requested(request_values[:date_requested])
    click_on 'Continue'

    expect(cases_show_page).to be_displayed
    row = cases_show_page.data_requests.rows[1]
    expect(row.location).to have_text 'HMP Leicester'
    expect(row.request_type).to have_text 'Other'
    expect(row.request_type).to have_text 'Lorem ipsum'
    expect(row.date_requested).to have_text '15 Aug 2020'
    data_requests = cases_show_page.data_requests.rows
    expect(data_requests.size).to eq 3

    last_row = cases_show_page.data_requests.rows.last
    expect(last_row).to have_selector '.total-label'
    expect(last_row.total_label).to have_text 'Total'
    expect(last_row).to have_selector '.total-value'
    expect(last_row.total_value).to have_text '0'
  end

  scenario 'partial data entry fails' do
    cases_show_page.load(id: offender_sar_complaint.id)
    click_on 'Requires data'
    click_on 'Record data request'

    # Note only filling in Location field, ommitting corresponding Data field
    data_request_page.form.location.fill_in(with: 'HMP Brixton')
    click_on 'Continue'

    expect(data_request_page).to be_displayed
    expect(data_request_page).to have_text 'errors prevented this form'
  end

  scenario 'no data entry fails' do
    cases_show_page.load(id: offender_sar_complaint.id)
    click_on 'Requires data'
    click_on 'Record data request'

    data_request_page.form.location.fill_in(with: '    ')
    data_request_page.form.request_type.fill_in(with: '')

    click_on 'Continue'

    expect(data_request_page).to be_displayed
    expect(data_request_page).to have_text '3 errors prevented this form from being submitted'
  end
end
