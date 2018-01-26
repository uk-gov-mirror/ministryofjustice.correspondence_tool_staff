class ChangeKiloMapName < ActiveRecord::Migration[5.0]
  def up
    rt = ReportType.find_by_abbr!('R006')
    rt.full_name = "Business Unit Map"
    rt.save!
  end

  def down
    rt = ReportType.find_by_abbr!('R006')
    rt.full_name = "Kilo Map"
    rt.save!
  end
end
