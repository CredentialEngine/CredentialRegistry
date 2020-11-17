require File.expand_path('../config/environment', __FILE__)
require 'rack/cors'

use Rack::TryStatic, root: 'public', urls: %w[/], try: %w[.html index.html]

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :get
  end
end

use Skylight::Middleware if ENV['RACK_ENV'] == 'production'
run API::Base
