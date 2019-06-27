require 'dotenv'

if %w[development test].include?(ENV['RACK_ENV'])
  Dotenv.load(
    ".env.#{ENV['RACK_ENV']}.local",
    '.env.local',
    ".env.#{ENV['RACK_ENV']}",
    '.env'
  )
end
