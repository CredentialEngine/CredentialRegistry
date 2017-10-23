# consider adding trgm extension to your template for running restore
#  >> psql -d template1 -c 'create extension pg_trgm;'
namespace :db do
  desc 'Dumps the database.'
  task dump: :environment do
    config = ActiveRecord::Base.connection_config

    dump_cmd = <<-bash
      PGPASSWORD=#{config[:password]} \
      pg_dump \
        --port #{config[:port]} \
        --host #{config[:host]} \
        --username #{config[:username]} \
        --clean \
        --no-owner \
        --no-acl \
        --format=c \
        -n public \
        #{config[:database]} > #{MR.root_path}/db/dump/content.dump
    bash

    puts "Dumping #{MR.env} database."

    raise unless system(dump_cmd)
  end

  desc 'Runs pg_restore.'
  task pg_restore: [:environment] do
    config = ActiveRecord::Base.connection_config

    restore_cmd = <<-bash
      PGPASSWORD=#{config[:password]} \
      pg_restore \
        --port=#{config[:port]} \
        --host=#{config[:host]} \
        --username=#{config[:username]} \
        --no-owner \
        --no-acl \
        -n public \
        --dbname=#{config[:database]} #{MR.root_path}/db/dump/content.dump
    bash

    puts "Restoring #{MR.env} database."

    raise unless system(restore_cmd)
  end

  desc 'Drops, creates and restores the database from a dump.'
  task restore: %i[environment drop create pg_restore]

  desc 'Backs up the database.'
  task backup: :environment do
    config = ActiveRecord::Base.connection_config

    backup_cmd = <<-bash
      BACKUP_FOLDER=$HOME/database_backups/`date +%Y_%m_%d`
      BACKUP_NAME=metadataregistry_`date +%s`.dump
      BACKUP_PATH=$BACKUP_FOLDER/$BACKUP_NAME

      mkdir -p $BACKUP_FOLDER

      PGPASSWORD=#{config[:password]} pg_dump \
          -h #{config[:host] || 'localhost'} \
          -U #{config[:username]} \
          --no-owner \
          --no-acl \
          -n public \
          -F c \
          #{config[:database]} \
          > $BACKUP_PATH

      echo "-> Backup created in $BACKUP_PATH."
    bash

    puts "Backing up #{MR.env} database."

    raise unless system(backup_cmd)
  end
end
