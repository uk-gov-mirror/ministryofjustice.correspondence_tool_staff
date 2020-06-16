namespace :db do

  desc 'Erase all tables'
  task :clear => :environment do
    HostEnv.safe do
      clear_database
    end
  end

  desc 'Clear the database, run migrations and basic seeds (not users, teams, roles)'
  task :reseed => :clear do
    Rake::Task['db:structure_load'].invoke
    Rake::Task['data:migrate'].invoke
  end

  task :structure_load => :environment do
    structure_file = "#{Rails.root}/db/structure.sql"

    command = if ENV["DATABASE_URL"]
      "psql #{ENV["DATABASE_URL"]} < #{structure_file}"
    else
      "psql -d correspondence_platform_development < #{structure_file}"
    end

    system command
  end

  def clear_database
    conn = ActiveRecord::Base.connection
    tables = conn.tables
    tables.each do |table|
      puts "Deleting #{table}"
      conn.drop_table(table, force: :cascade)
    end

    enum_types = %w(
      assignment_type
      attachment_type
      requester_type
      state
      user_role
      team_roles
      cases_delivery_methods
      search_query_type
    )
    enum_types.each do |type|
      conn.execute("DROP TYPE IF EXISTS #{type}")
    end
  end

end

