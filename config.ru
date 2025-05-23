require File.expand_path('config/environment', __dir__)
require 'rack/cors'
require 'sidekiq/web'

use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           secret: ENV.fetch('SECRET_KEY_BASE')

use Rack::TryStatic, root: 'public', urls: %w[/], try: %w[.html index.html]

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :get
  end
end

use Airbrake::Rack::Middleware if ENV['AIRBRAKE_PROJECT_ID'].present?

map '/sidekiq' do
  unless MR.env == 'development'
    use Rack::Auth::Basic, 'Protected Area' do |username, password|
      username_matches = Rack::Utils.secure_compare(
        Digest::SHA256.hexdigest(username),
        Digest::SHA256.hexdigest(ENV.fetch('SIDEKIQ_USERNAME', nil))
      )

      password_matches = Rack::Utils.secure_compare(
        Digest::SHA256.hexdigest(password),
        Digest::SHA256.hexdigest(ENV.fetch('SIDEKIQ_PASSWORD', nil))
      )

      username_matches && password_matches
    end
  end

  run Sidekiq::Web
end

run API::Base
