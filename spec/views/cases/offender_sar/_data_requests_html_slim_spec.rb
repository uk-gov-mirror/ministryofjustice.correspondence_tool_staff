require 'rails_helper'

describe 'cases/offender_sar/data_requests.html.slim', type: :view do
  let(:offender_sar_case) {
    (create :offender_sar_case, subject_aliases: 'John Smith',
            date_of_birth: '2019-09-01').decorate
  }
  let(:branston_user)             { find_or_create :branston_user }


  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  before(:each) { login_as branston_user }

  describe 'basic_details' do
    let!(:data_request) {
      create(
        :data_request, case_id: offender_sar_case.id,
        location: 'HMP Leicester',
        data: 'How many pencils were used by Dave',
        cached_num_pages: 32,
        cached_date_received: Date.new(1972, 9, 25)
      )
    }


    it 'displays the initial case details (non third party case)' do
      assign(:case, offender_sar_case)
      render partial: 'cases/offender_sar/data_requests.html.slim',
             locals: { case_details: offender_sar_case }

    partial = cases_show_page.load(rendered)
    byebug
    last_row = cases_show_page.data_requests.rows.last
    expect(last_row.total_value).to have_text '32'
   end
 end

end
