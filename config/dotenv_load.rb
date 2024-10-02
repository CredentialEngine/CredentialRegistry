if %w[development test].include?(ENV['RACK_ENV'])
  require 'dotenv'

  Dotenv.load(
    ".env.#{ENV['RACK_ENV']}.local",
    ".env.#{ENV['RACK_ENV']}",
    '.env'
  )
end
