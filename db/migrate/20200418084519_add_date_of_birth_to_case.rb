class AddDateOfBirthToCase < ActiveRecord::Migration[5.0]
  def change
    add_column :cases, :date_of_birth, :date, null: true
  end
end
