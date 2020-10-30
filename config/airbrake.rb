project_id = ENV['AIRBRAKE_PROJECT_ID']
project_key = ENV['AIRBRAKE_PROJECT_KEY']

if project_id.present? && project_key.present?
  Airbrake.configure do |c|
    c.environment = ENV.fetch('RACK_ENV')
    c.project_id = project_id
    c.project_key = project_key
  end
end
