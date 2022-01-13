if %w[development test].include?(ENV['RACK_ENV'])
  require 'dotenv'

  Dotenv.load(
    ".env.#{ENV['RACK_ENV']}",
    ".env",
  )

  Dotenv.overload(
    ".env.#{ENV['RACK_ENV']}.local",
    ".env.local",
  )
end
