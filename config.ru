require File.expand_path('../config/environment', __FILE__)

use ActiveRecord::ConnectionAdapters::ConnectionManagement

use Rack::TryStatic, root: 'public', urls: %w(/), try: %w(.html index.html)

run API::Base
