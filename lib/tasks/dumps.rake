namespace :dumps do
  desc 'Loads application environment'
  task :environment do
    require File.expand_path('../../../config/environment', __FILE__)
  end

  desc 'Backups a transaction dump file to a remote provider. ' \
       'Arguments: - dump date (optional, defaults to yesterday), ' \
       '- provider (optional, defaults to InternetArchive) ' \
       '- community_name (optional, defaults to all)'
  task :backup, %i[date provider community] => [:environment] do |_, args|
    require 'generate_envelope_dump'
    date = parse_date(args[:date])
    community_name = args[:community]

    if community_name
      backup(date, EnvelopeCommunity.find_by(name: community_name),
             community_name.titleize, args[:provider])
    else
      each_community do |community, name|
        backup(date, community, name, args[:provider])
      end
    end
  end

  desc 'Restores envelopes from a remote provider into the local database. '\
       'Arguments: - starting date (optional, defaults to yesterday), ' \
       '- provider (optional, defaults to InternetArchive) ' \
       '- community_name (optional, defaults to all)'
  task :restore, %i[from_date provider community] => [:environment] do |_, args|
    require 'restore_envelope_dumps'
    from_date = parse_date(args[:from_date])
    community_name = args[:community]

    if community_name
      restore(from_date, EnvelopeCommunity.find_by(name: community_name),
              community_name.titleize, args[:provider])
    else
      each_community do |community, name|
        restore(from_date, community, name, args[:provider])
      end
    end
  end

  def parse_date(date)
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

  # rubocop:disable Metrics/AbcSize
  def backup(date, community, name, provider)
    provider = S3.new(community.backup_item) if provider =~ /s3/i

    dump_generator = GenerateEnvelopeDump.new(date, community, provider)
    puts "[#{name}] Dumping transactions from #{fmt(date)}"
    dump_generator.run

    puts "[#{name}] Uploading file #{dump_generator.dump_file}"
    dump_generator.provider.upload(dump_generator.dump_file)
  ensure
    puts "[#{name}] Removing temporary file"
    FileUtils.safe_unlink(dump_generator.dump_file)
  end
  # rubocop:enable Metrics/AbcSize

  def restore(from_date, community, name, provider)
    provider = S3.new(community.backup_item) if provider =~ /s3/i
    puts "[#{name}] Restoring transactions from #{fmt(from_date)} to today"
    RestoreEnvelopeDumps.new(from_date, community, provider).run
  end
end
