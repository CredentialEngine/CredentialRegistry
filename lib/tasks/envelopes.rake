namespace :envelopes do
  desc 'Loads application environment'
  task :environment do
    require File.expand_path('../../../config/environment', __FILE__)
  end

  desc 'Creates an envelope community'
  task :create_community, %i[name backup_item] => [:environment] do |_, args|
    comm = EnvelopeCommunity.create(name: args[:name],
                                    backup_item: args[:backup_item])
    if comm
      puts "EnvelopeCommunity #{args[:name]} created"
    else
      puts comm.errors.full_messages
    end
  end

  desc 'Clear community envelopes'
  task :clear_community, [:name] => [:environment] do |_, args|
    Envelope.in_community(args[:name]).destroy_all if args[:name].present?
  end

  desc 'Copy schemas from one community to another'
  task :copy_community, %i[from_comm new_comm] => [:environment] do |_, args|
    # create new community
    Rake::Task['envelopes:create_community'].invoke(args[:new_comm])

    # copy configs
    root_path = File.expand_path('../../../', __FILE__)
    ['app/schemas', 'config/authorized_keys'].each do |dir|
      from_folder = File.join(root_path, dir, args[:from_comm])
      new_folder  = File.join(root_path, dir, args[:new_comm])

      FileUtils.copy_entry from_folder, new_folder
    end
  end
end
