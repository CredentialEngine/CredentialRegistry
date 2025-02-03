include ActiveRecord::Tasks # rubocop:todo Style/MixinUsage

class Seeder # rubocop:todo Style/Documentation
  attr_reader :seed_file

  def initialize(seed_file)
    @seed_file = seed_file
  end

  def load_seed
    raise "Seed file `#{seed_file}` doesn't exist" unless File.file?(seed_file)

    load(seed_file)
  end
end

DatabaseTasks.db_dir = MR.root_path.join('db')
DatabaseTasks.env = ENV.fetch('RACK_ENV', nil)
DatabaseTasks.migrations_paths = [MR.root_path.join('db/migrate')]
DatabaseTasks.root = MR.root_path
DatabaseTasks.seed_loader = Seeder.new(MR.root_path.join('db/seeds.rb'))

load 'active_record/railties/databases.rake'

task :environment do
  Rake::Task['cer_environment'].execute
end
