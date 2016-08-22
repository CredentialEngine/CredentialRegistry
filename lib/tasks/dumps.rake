namespace :dumps do
  desc 'Loads application environment'
  task :environment do
    require File.expand_path('../../../config/environment', __FILE__)
  end

  desc 'Backups a transaction dump file to a remote provider. '\
       'Accepts an argument to specify the dump date (defaults to yesterday)'
  task :backup, [:date] => [:environment] do |_, args|
    require 'generate_envelope_dump'

    date = parse(args[:date])
    each_community do |community, name|
      dump_generator = GenerateEnvelopeDump.new(date, community)
      begin
        puts "[#{name}] Dumping transactions from #{fmt(date)}..."
        dump_generator.run

        puts "[#{name}] Uploading file #{dump_generator.dump_file}..."
        dump_generator.provider.upload(dump_generator.dump_file)
      ensure
        puts "[#{name}] Removing temporary file..."
        FileUtils.safe_unlink(dump_generator.dump_file)
      end
    end
  end

  desc 'Restores envelopes from a remote provider into the local database. '\
       'Accepts an argument to specify the starting date (defaults to '\
       'yesterday)'
  task :restore, [:from_date] => [:environment] do |_, args|
    require 'restore_envelope_dumps'

    from_date = parse(args[:from_date])

    each_community do |community, name|
      puts "[#{name}] Restoring transactions from #{fmt(from_date)} to today"
      RestoreEnvelopeDumps.new(from_date, community).run
    end
  end

  def parse(date)
    Date.parse(date.to_s)
  rescue ArgumentError
    Date.current - 1
  end

  def fmt(date)
    date.strftime('%b %d, %Y')
  end

  def each_community
    EnvelopeCommunity.find_each do |community|
      name = community.name.titleize
      yield(community, name)
    end
  end
end
