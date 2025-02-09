
# This taks is to provide the following functions
# - anonymizer: dump anonymised db as compressed-sql files against the database the app is connecting to currently
#   This part doesn't assume where the command is run (cloud or local env) with opition of uploading to s3 bucket
# 
#   The process of db anoymizer is below
#     - validate (?)
#     - create the snapshot of current db structure and the snapshot of the 
#     - dump the data out of db per table base
#       - check whether this table is within the tables which require anonymised
#       - if does, then call anon
#       - compress the outcome 
#       -  upload into s3 bucket.
# - s3 bucket related tasks
#   -- List all the files under certain key path
#   -- Download the files under certain key path
#   -- Delete the files under certain key path
# - restorer 
#    restore the sql files into target db (non-prod env) 
#    -- drop the schema at target table
#    -- import the data per table bases into the target the db
#    -- run migratoins
#    -- run udpate for search index
#    -- restart the instances
#    -- not sure whether we need to reindex at database level

#   Safegurd checking 
#   - manul checking list
#   - auto-checking approach 
#     e.g. - any database schema changes and the data model's attributes changes
#      keep the latest coppy of schema and the data model structure 
#      scan current db schema and data models structure
#      calculate the hash value/ md5_sum values based on the content of current and latest copy
#      if different, then die out 
#      The only way which can fix this problem is to run separated task to update the copy in the cloud
# - wrapper:  
#   This task is to wrap the above tasks into a task to export data from live and anonymize it 

require File.join(Rails.root, 'lib', 'tasks', 'rake_task_helpers', 'dumper_utils')

namespace :db do
  namespace :dump  do

    desc 'Help text for rake db:dump:* tasks'
    task :help do
      puts 'rake db:dump:prod will produce an SQL dump of the database from the '.yellow
      puts 'rake db:dump:local will dump and anonymize again the database the current env/pod connects with '.yellow
      puts 'rake db:dump:list_s3_dumps will list all the files under dumps folder'.yellow
      puts 'rake db:dump:delete_s3_dumps will delete all the files under dumps folder'.yellow
      puts 'rake db:dump:copy_s3_dump will download all the files under dumps folder'.yellow
      puts 'rake db:dump:decompress will decompress alt the gz files under dumps folder'.yellow
      puts 'rake db:dump:restore will process restore '.yellow
    end


    desc 'makes a sql dump of the production database and copies to the local machine'
    task :prod do |_task|
      require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
      safeguard
      chosen_first_pod = get_first_pod("production")
      raise "Cannot find the available pod from this env" unless chosen_first_pod.present?

      prefix_command = "kubectl exec -it #{chosen_first_pod} -n track-a-query-production -c webapp "
      dump_files = DatabaseDumper.new(true).run
      dump_files.each do | compressed_file |
        DumperUtils.download_compressed_file(compressed_file, "track-a-query-production", chosen_first_pod)
        DumperUtils.remove_files_on_container(compressed_file, prefix_command: prefix_command)
      end
    end

    # desc 'makes an sql dump of the database on the demo environement to the local machine'
    # task :demo, [:host] do |_task, args|
    #   # require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
    #   DatabaseDumper.new('demo', args[:host], 'clear').run
    # end

    # desc 'makes an sql dump of the database on the staging environment to the local machine'
    # task :staging, [:host] do |_task, args|
    #   # require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
    #   DatabaseDumper.new('demo', args[:host], 'clear').run
    # end

    desc 'makes an anonymised dump of the local database'
    task :local, [:anonymized, :tag, :storage, :bucket_key_id, :bucket_access_key, :bucket] => :environment do |_task, args|
      require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
      raise "first argument must be 'anon' or 'clear', is: #{args[:anonymized]}" unless args[:anonymized].in?(%w( anon clear ))
      args.with_defaults(:tag => "latest")
      args.with_defaults(:storage => "bucket")
      raise "third argument must be 'bucket' or 'local', is: #{args[:storage]}" unless args[:storage].in?(%w( bucket local ))

      is_store_to_s3_bucket = args[:storage] == 'bucket'
      puts 'exporting unanonymised database data'
      dumper = DatabaseDumper.new(
        args[:anonymized] == 'anon', 
        args[:tag], 
        is_store_to_s3_bucket)
      if is_store_to_s3_bucket
        dumper.set_up_bucket(args)
      end
      dumper.run
    end

    desc 'List s3 database dump files'
    task :list_s3_dumps, [:tag, :bucket_key_id, :bucket_access_key, :bucket] => :environment do |_task, args|
      include ActionController
      args.with_defaults(:tag => "latest")
      s3_bucket = init_s3_bucket(args)
      puts "Listing dump files in s3 with tag of #{args[:tag]} from bucket #{args[:bucket]}"
      dump_files = s3_bucket.list("dumps/#{args[:tag]}")
      dump_files.sort_by(&:last_modified).reverse.map do |object|
        puts "Key: #{object.key}"
        puts "Last modified: #{object.last_modified.iso8601}"
        puts "Size: #{ActionController::Base.helpers.number_to_human_size(object.content_length)}"
        puts '-----------------------------------------------------'
      end
    end

    desc 'Delete all but latest s3 database dump files'
    task :delete_s3_dumps, [:tag, :bucket_key_id, :bucket_access_key, :bucket] => :environment do |_task, args|
      args.with_defaults(:tag => "latest")
      s3_bucket = init_s3_bucket(args)
      puts "Delete dump files in s3 with tag of #{args[:bucket]}"
      DumperUtils.question_user(
        'Are you sure the folder under the bucket is not the folder of storing important user files? Please check the following files carefully. ')
      dump_files = s3_bucket.list("dumps/#{args[:tag]}")
      dump_files.sort_by(&:last_modified).reverse.map do |object|
        puts "Key: #{object.key}"
      end
      confirm_delete_dumps_file
      dump_files.sort_by(&:last_modified).map do |object|
        print "Deleting #{object.key}..."
        object.delete
        puts 'done'.green
      end
    end

    desc 'Copy s3 bucket dump file locally and decompress'
    task :copy_s3_dumps, [:tag, :bucket_key_id, :bucket_access_key, :bucket] => :environment do |_task, args|
      args.with_defaults(:tag => "latest")
      s3_bucket = init_s3_bucket(args)
      dir_name_base = "dumps_#{args[:tag]}_from_#{args[:bucket]}"
      dirname = Rails.root.join(dir_name_base)
      FileUtils.mkpath(dirname)
      DumperUtils.shell_working "Copying S3 files under dumps/#{args[:tag]} to local folder #{dirname}" do
        dump_files = s3_bucket.list("dumps/#{args[:tag]}")
        dump_files.map do |dump_file|
          local_filename = Rails.root.join(dir_name_base, dump_file.key.split(File::Separator).last)
          File.open(local_filename, 'wb') do |file|
            s3_bucket.get_object(dump_file.key, target: file)
          end
        end 
      end
      
      DumperUtils.shell_working "Decompress all those sql files from local folder #{dirname}" do
        Dir.glob("#{dirname}/*.gz").sort.map do | local_filename |
          DumperUtils.decompress_file(local_filename)
        end
      end
    end    

    desc 'Decompress downloaded files'
    task :decompress, [:tag] => :environment do |_task, args|
      args.with_defaults(:tag => "latest")
      dirname = Rails.root.join("dumps_#{args[:tag]}")      
      DumperUtils.shell_working "Decompress all those sql files from local folder #{dirname}" do
        Dir.glob("#{dirname}/*.gz").sort.map do | local_filename |
          DumperUtils.decompress_file(local_filename)
        end
      end
    end    

    private

    def safeguard
      puts 'Are you sure you need to do this data dump?'
      puts ''
      DumperUtils.question_user('is the issue covered with existing feature tests? ')
      DumperUtils.question_user('can you track problem through Kibana? ')
      DumperUtils.question_user('can you recreate the problem locally? ')
      DumperUtils.question_user('can you recreate the problem on staging with an anonymised dump? ')
      confirm_data_dump
    end

    def confirm_data_dump
      print "If you are still certain that you need to make a dump of the database please confirm y/n "
      input = STDIN.gets.chomp
      exit unless(input.downcase.start_with?('y')) || input.nil?
    end

    def confirm_delete_dumps_file
      print "If you are still certain that you need to delete the files, please confirm Y/n?"
      input = STDIN.gets.chomp
      exit unless(input.start_with?('Y')) || input.nil?
    end

    def get_first_pod(working_env)
      require 'open3'

      pod_name = nil
      output = Open3.popen3("kubectl get pods -n track-a-query-#{working_env}") { |_, stdout, _, _| stdout.read }
      if output.present?
        output_lines = output.split('\n')
        if output_lines.count >= 2
          pod_name = output_lines[1].split(' ')[0].delete(' ')
        end 
      end
      pod_name
    end

    def init_s3_bucket(args)
      args.with_defaults(:bucket_key_id => ENV["AWS_ACCESS_KEY_ID"])
      args.with_defaults(:bucket_access_key => ENV["AWS_SECRET_ACCESS_KEY"])
      args.with_defaults(:bucket => Settings.case_uploads_s3_bucket)
      s3_bucket = S3BucketHelper::S3Bucket.new(
        args[:bucket_key_id], 
        args[:bucket_access_key],
        bucket: args[:bucket])
      s3_bucket
    end
  end

  namespace :restore do

    desc 'Loads an SQL dump of the database created by db:dump:<env> rake task to the local database'
    task :local, [:dir] => :environment do |_task, args|
      if is_on_production?
        puts "Cannot run this command on production environment!"
      else
        safeguard
        args.with_defaults(:dir => "dumps_latest")
        dirname = Rails.root.join(args[:dir])
  
        require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_loader')
        env = ENV['ENV'] || 'local'
        raise "This task is not allowed on non-prod environment." unless env != 'prod'
        DatabaseLoader.new(env, dirname).run
      end    
    end

    private

    def is_on_production?
      ENV['ENV'].present? && ENV['ENV'] == 'prod'
    end

    def safeguard
      puts 'Are you sure you need to retore a dump of database into the current database the app is connecting to?'
      puts 'Precondition: a dump of entire database has been done before carryihng this task'
      puts 'NOTES: rstoring process will destroy the previous data entirely, backup the data first if there is need'
      DumperUtils.question_user('Are you sure the current environment is not production? ')
      confirm_data_restore
      puts 'After action: you may need to restart your app server instance in order to making it work properly'
    end

    def confirm_data_restore
      print "If you are still certain that you need to restore the data from dump files please confirm Y/n "
      input = STDIN.gets.chomp
      exit unless(input.start_with?('Y')) || input.nil?
    end

  end

end
