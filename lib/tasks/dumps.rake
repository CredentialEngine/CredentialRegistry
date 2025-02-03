namespace :dumps do
  desc 'Backups a transaction dump file to a remote provider. ' \
       'Accepts an argument to specify the dump date (defaults to yesterday)'
  task :backup, [:date] => :cer_environment do |_, args|
    require 'generate_envelope_dump'

    date = parse(args[:date])
    each_community do |community, name|
      next unless community.backup_item?

      dump_generator = GenerateEnvelopeDump.new(date, community)
      begin
        puts "[#{name}] Dumping transactions from #{fmt(date)}..."
        dump_generator.run

        file = dump_generator.dump_file
        puts "[#{name}] Uploading file #{dump_generator.dump_file}..."
        puts "[#{name}} File will be uploaded to #{dump_generator.provider.location(file)}"
        dump_generator.provider.upload(file)
      ensure
        puts "[#{name}] Removing temporary file..."
        FileUtils.safe_unlink(dump_generator.dump_file)
      end
    end
  end

  desc 'Backup all transactions, per day, until today'
  task backup_all: :cer_environment do
    transactions = EnvelopeTransaction.select(:created_at)
    dates = transactions.map { |e| e.created_at.to_date }.uniq.sort
    dates.each do |date|
      puts "===> Backing up transactions for #{date}"
      task = Rake::Task['dumps:backup']
      task.invoke date.to_s
      task.reenable
    end
  end

  desc 'Restores envelopes from a remote provider into the local database. ' \
       'Accepts an argument to specify the starting date (defaults to ' \
       'yesterday)'
  task :restore, [:from_date] => :cer_environment do |_, args|
    require 'restore_envelope_dumps'

    from_date = parse(args[:from_date])

    each_community do |community, name|
      puts "[#{name}] Restoring transactions from #{fmt(from_date)} to today"
      next unless community.backup_item?

      RestoreEnvelopeDumps.new(from_date, community).run
    end
  end

  def parse(date) # rubocop:todo Rake/MethodDefinitionInTask
    Date.parse(date.to_s)
  rescue ArgumentError
    Date.current - 1
  end

  def fmt(date) # rubocop:todo Rake/MethodDefinitionInTask
    date.strftime('%b %d, %Y')
  end

  def each_community # rubocop:todo Rake/MethodDefinitionInTask
    EnvelopeCommunity.find_each do |community|
      name = community.name.titleize
      yield(community, name)
    end
  end
end
