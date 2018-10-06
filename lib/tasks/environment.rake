desc 'Sets up the application environment.'
task :cer_environment do
  require File.expand_path('../../config/environment', __dir__)
end
