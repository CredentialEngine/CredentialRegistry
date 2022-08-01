include ActiveRecord::Tasks

class Seeder
  attr_reader :seed_file

  def initialize(seed_file)
    @seed_file = seed_file
  end

  def load_seed
    unless File.file?(seed_file)
      raise "Seed file `#{seed_file}` doesn't exist"
    end

    load(seed_file)
  end
end

DatabaseTasks.db_dir = MR.root_path.join('db')
DatabaseTasks.env = ENV['RACK_ENV']
DatabaseTasks.migrations_paths = [MR.root_path.join('db/migrate')]
DatabaseTasks.root = MR.root_path
DatabaseTasks.seed_loader = Seeder.new(MR.root_path.join('db/seeds.rb'))

load 'active_record/railties/databases.rake'

task :environment do
  Rake::Task['cer_environment'].execute
end
