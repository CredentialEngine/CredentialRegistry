project_id = ENV.fetch('AIRBRAKE_PROJECT_ID', nil)
project_key = ENV.fetch('AIRBRAKE_PROJECT_KEY', nil)

if project_id && project_key
  require 'airbrake'
  require 'airbrake/rack'

  if defined?(Sidekiq)
    Sidekiq.configure_server do |config|
      config.on(:startup) do
        require 'airbrake/sidekiq'
      end
    end
  end

  Airbrake.configure do |c|
    c.environment = ENV.fetch('RACK_ENV')
    c.project_id = project_id
    c.project_key = project_key
    c.blocklist_keys = %i[apikey api_key password]
  end
end
