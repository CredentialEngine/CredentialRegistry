require File.expand_path('../config/environment', __FILE__)
require 'rack/cors'

use ActiveRecord::ConnectionAdapters::ConnectionManagement

use Rack::TryStatic, root: 'public', urls: %w(/), try: %w(.html index.html)

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :get
  end
end

run API::Base
