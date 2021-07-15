project_id = ENV['AIRBRAKE_PROJECT_ID']
project_key = ENV['AIRBRAKE_PROJECT_KEY']

if project_id && project_key
  require 'airbrake'
  require 'airbrake/rack'

  if defined?(Sidekiq)
    Sidekiq.on(:startup) do
      require 'airbrake/sidekiq'
    end
  end

  Airbrake.configure do |c|
    c.environment = ENV.fetch('RACK_ENV')
    c.project_id = project_id
    c.project_key = project_key
    c.blocklist_keys = %i[apikey api_key password]
  end
end
