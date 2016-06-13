namespace :dumps do
  desc 'Loads application environment'
  task :environment do
    require File.expand_path('../../../config/environment', __FILE__)
  end

  desc 'Backups a transaction dump file to a remote provider. '\
       'Accepts an argument to specify the dump date (defaults to yesterday)'
  task :backup, [:date] => [:environment] do |_, args|
    require 'envelope_dump'
    require 'generate_envelope_dump'

    date = parse(args[:date])
    provider = InternetArchive.new
    dump_generator = GenerateEnvelopeDump.new(date, provider)

    begin
      puts "Dumping transactions from #{format(date)}..."
      dump_generator.run

      puts "Uploading file #{dump_generator.dump_file}..."
      provider.upload(dump_generator.dump_file)
    ensure
      puts 'Removing temporary file...'
      FileUtils.safe_unlink(dump_generator.dump_file)
    end
  end

  desc 'Restores envelopes from a remote provider into the local database. '\
       'Accepts an argument to specify the starting date (defaults to '\
       'yesterday)'
  task :restore, [:from_date] => [:environment] do |_, args|
    require 'restore_envelope_dumps'

    from_date = parse(args[:from_date])

    puts "Restoring transactions from #{format(from_date)} to today"
    RestoreEnvelopeDumps.new(from_date).run
  end

  def parse(date)
    Date.parse(date.to_s)
  rescue ArgumentError
    Date.current - 1
  end

  def format(date)
    date.strftime('%b %d, %Y')
  end
end
