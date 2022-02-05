if %w[development test].include?(ENV['RACK_ENV'])
  require 'dotenv'

  Dotenv.load(
    ".env",
    ".env.#{ENV['RACK_ENV']}",
  )

  Dotenv.overload(
    ".env.local",
    ".env.#{ENV['RACK_ENV']}.local",
  )
end
