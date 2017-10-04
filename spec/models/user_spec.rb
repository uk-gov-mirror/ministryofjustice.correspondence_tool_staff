# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  full_name              :string           not null
#  deleted_at             :datetime
#

require 'rails_helper'

RSpec.describe User, type: :model do

  subject { create(:user) }

  it { should have_many(:assignments) }
  it { should have_many(:cases)       }
  it { should validate_presence_of(:full_name) }
  it { should have_many(:team_roles).class_name('TeamsUsersRole') }
  it { should have_many(:teams).through(:team_roles) }
  it { should have_many(:managing_team_roles).class_name('TeamsUsersRole') }
  it { should have_many(:responding_team_roles).class_name('TeamsUsersRole') }
  it { should have_one(:approving_team_roles).class_name('TeamsUsersRole') }
  it { should have_many(:managing_teams).through(:managing_team_roles) }
  it { should have_many(:responding_teams).through(:responding_team_roles) }
  it { should have_one(:approving_team).through(:approving_team_roles) }

  let(:manager)         { create :manager }
  let(:responder)       { create :responder }
  let(:approver)        { create :approver }
  let(:press_officer)   { create :press_officer }
  let(:deactivated_user){ create :deactivated_user }

  describe '#manager?' do
    it 'returns true for a manager' do
      expect(manager.manager?).to be true
    end

    it 'returns false for a responder' do
      expect(responder.manager?).to be false
    end

    it 'returns false for an approver' do
      expect(approver.manager?).to be false
    end
  end

  describe '#responder?' do
    it 'returns false for a manager' do
      expect(manager.responder?).to be false
    end

    it 'returns true for a responder' do
      expect(responder.responder?).to be true
    end

    it 'returns false for an approver' do
      expect(approver.responder?).to be false
    end
  end

  describe '#approver?' do
    it 'returns false for a manager' do
      expect(manager.approver?).to be false
    end

    it 'returns false for a responder' do
      expect(responder.approver?).to be false
    end

    it 'returns true for an approver' do
      expect(approver.approver?).to be true
    end
  end

  describe '#roles' do
    it 'returns the roles given users' do
      expect(manager.roles).to eq ['manager']
    end
  end

  describe 'press_officer?' do
    it 'returns true if user is in press office team' do
      expect(press_officer.press_officer?).to be true
    end

    it 'returns false if the user is not in the press office' do
      find_or_create :team_press_office
      expect(approver.press_officer?).not_to be true
    end
  end

  describe '#team_for_case' do
    context 'user is in one of the teams associated with the case' do
      it 'returns that user' do
        kase = create :pending_dacu_clearance_case
        responder = kase.responder
        expect(responder.teams_for_case(kase)).to eq [ kase.responding_team ]
      end
    end
  end

  describe '#soft_delete' do
    it 'updates the deleted_at attribute' do
      subject.soft_delete
      expect(subject.deleted_at).not_to be nil
    end
  end

  describe '#active_for_authentication' do
    it 'return true for active user' do
      expect(subject.active_for_authentication?).to be true
    end
    it 'returns false for deactivated user' do
      subject.soft_delete
      expect(subject.active_for_authentication?).to be false
    end
  end

  describe '#has_live_cases?' do

    let(:closed_case)     { create :closed_case }
    let(:assigned_case)   { create :assigned_case }
    let(:responder)       { responding_team.responders.first }
    let(:assignment)      { assigned_case.responder_assignment }
    let(:responding_team) { assignment.team }

    it 'returns false for a user with no assignments' do
      expect(subject.has_live_cases?).to be false
    end

    it 'returns true for a user with an open case' do
      assignment = assigned_case.responder_assignment
      assignment.accept(responder)
      expect(responder.has_live_cases?).to be true
    end

    it 'returns false for a user with a closed case' do
      assignment = closed_case.responder_assignment
      expect(assignment.user.has_live_cases?).to be false
    end
  end

  describe '#multiple_team_member?' do

    it 'returns false for a user with one team' do
      expect(responder.multiple_team_member?).to be false
    end
    it 'returns true for a user with mulitple teams' do
      team = create :responding_team, name: 'User Creation Team'
      existing_user = User.new(full_name: 'danny driver', email: 'dd@moj.com', password: 'kjkjkj')
      existing_user.team_roles << TeamsUsersRole.new(team: team, role: 'responder')
      team_2 = BusinessUnit.create(name: 'UCT 2', parent_id: team.parent_id, role: 'responder')
      existing_user.team_roles << TeamsUsersRole.new(team: team_2, role: 'responder')
      existing_user.save!
      expect(existing_user.multiple_team_member?).to be true
    end
  end

  describe 'paper_trail versions', versioning: true do

    it 'has versions' do
      it { is_expected.to be_versioned }
    end

    context 'on create' do
      it 'updates versions' do
        expect(responder.versions.length).to eq 1
        expect(responder.versions.last.event).to eq 'create'
      end
    end

    context 'on update' do

      it 'updates versions' do
        expect{responder.update_attributes!(full_name: 'Namerson')}.to change(responder.versions, :count).by 1
        expect(responder.versions.last.event).to eq 'update'
      end
    end
  end
end
