require 'rails_helper'

feature 'respond to responder assignment' do
  given(:responder)       { create :responder }
  given(:responding_team) { responder.responding_teams.first }
  given(:kase) do
    create(
      :assigned_case,
      subject: 'A message about XYZ',
      message: 'I would like to know about XYZ',
      responding_team: responding_team
    )
  end

  given(:assignment) do
    kase.responder_assignment
  end

  background do
    login_as responder
  end

  scenario 'kilo accepts assignment' do
    visit edit_case_assignment_path kase, assignment
    expect(page).to have_content kase.number
    expect(page).to have_content kase.subject
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'

    choose 'Accept'
    expect(page).
      to have_selector('#assignment_reasons_for_rejection', visible: false)
    click_button 'Confirm'

    expect(page).to have_current_path(case_path kase, accepted_now: true)
    expect(page).to have_content("You've accepted this case")

    expect(assignment.reload.state).to eq 'accepted'
    expect(kase.reload.current_state).to eq 'drafting'
    expect(kase.responder).to eq responder
  end

  scenario 'kilo rejects assignment' do
    visit edit_case_assignment_path kase, assignment
    expect(page).to have_content kase.number
    expect(page).to have_content kase.subject
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'
    expect(page).to have_content 'What do you want to do?'

    choose 'Reject'
    expect(page).
      to have_selector('#assignment_reasons_for_rejection', visible: true)
    fill_in 'Why are you rejecting this case?', with: 'This is not for me'
    click_button 'Confirm'

    expect(page).to have_current_path(case_assignments_show_rejected_path kase, rejected_now: true)
    expect(page).to have_content 'Your response has been sent'
    expect(page).
      to have_content(
        'This case will be reviewed and assigned the to appropriate unit.'
      )

    expect(page).to have_content(kase.number)
    expect(page).to have_content(kase.subject)
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'
    expect(page).not_to have_content 'What do you want to do?'

    expect(kase.reload.current_state).to eq 'unassigned'
  end

  scenario 'kilo rejects assignment but provides no reasons for rejection' do
    visit edit_case_assignment_path kase, assignment
    expect(page).to have_content kase.number
    expect(page).to have_content kase.subject
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'

    choose 'Reject'
    expect(page).
      to have_selector('#assignment_reasons_for_rejection', visible: true)
    click_button 'Confirm'

    expect(current_path).
      to eq accept_or_reject_case_assignment_path kase, assignment
    expect(page.find('#assignment_state_rejected')).to be_checked
    expect(page).
      to have_selector('#assignment_reasons_for_rejection', visible: true)
    expect(Assignment.find(assignment.id).state).to eq 'pending'
    expect(kase.reload.current_state).to eq 'awaiting_responder'
    expect(page).
      to have_content('1 error prevented this form from being submitted')
    expect(page).
      to have_content("Why are you rejecting this case? can't be blank")
  end

  scenario 'kilo tries to submit the form without selecting accept / reject' do
    visit edit_case_assignment_path kase, assignment
    expect(page).to have_content kase.number
    expect(page).to have_content kase.subject
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'

    click_button 'Confirm'

    expect(current_path).
      to eq accept_or_reject_case_assignment_path kase, assignment
    expect(page).
      to have_selector('#assignment_reasons_for_rejection', visible: false)
    expect(assignment.state).to eq 'pending'
    expect(kase.reload.current_state).to eq 'awaiting_responder'
    expect(page).
      to have_content('1 error prevented this form from being submitted')
    expect(page).
      to have_content("You must either accept or reject this case")
  end

  scenario 'kilo clicks on a link to an assignment that has been rejected' do
    assignment.reject responder, "NO thank you"

    visit edit_case_assignment_path kase, assignment.id

    expect(page).to have_current_path(
                      case_assignments_show_rejected_path kase,
                                                          rejected_now: false
                    )
    expect(page).to have_content('This case has already been rejected.')
  end

  scenario 'kilo clicks on a link to an assignment that has been accepted' do
    assignment_id = assignment.id
    assignment.accept responder

    visit edit_case_assignment_path kase, assignment_id

    expect(page).to have_current_path(case_path(kase, accepted_now: false))
    expect(page).to_not have_content("You've accepted this case")
    expect(page).to_not have_content('This case has already been rejected.')
  end

end
