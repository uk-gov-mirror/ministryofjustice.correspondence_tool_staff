require 'rails_helper'

feature 'Deadlines:' do

  background do
    Timecop.freeze('21/08/2016') do
      create(:correspondence)
      create(:correspondence, category: create(:category, :gq))
    end
    login_as create(:user)
  end

  context 'The internal deadline' do

    context 'for General Enquiries' do
      scenario 'is shown in the detail view' do
        visit "/correspondence/#{Correspondence.last.id}"
        expect(page).to have_content('Internal deadline')
        expect(page).to have_content('05/09/16')
      end
    end

    context 'for Freedom of Information Requests' do

      scenario 'is shown in the detail view' do
        visit "/correspondence/#{Correspondence.first.id}"
        expect(page).to have_content('Internal deadline')
        expect(page).to have_content('05/09/16')
      end
    end
  end

  context 'The external deadline' do

    context 'for General Enquiries' do
      scenario 'is shown in the detail view' do
        visit "/correspondence/#{Correspondence.last.id}"
        expect(page).to have_content('External deadline')
        expect(page).to have_content('12/09/16')
      end
    end

    context 'for Freedom of Information Requests' do
      scenario 'is shown in the detail view' do
        visit "/correspondence/#{Correspondence.first.id}"
        expect(page).to have_content('External deadline')
        expect(page).to have_content('19/09/16')
      end
    end

  end
end
