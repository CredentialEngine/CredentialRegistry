require 'v1/base'
require 'v2/base'

module API
  # Main base class that defines all API versions
  class Base < Grape::API
    helpers CommunityHelpers

    insert_after Grape::Middleware::Formatter, Grape::Middleware::Logger, {
      logger: MR.logger,
      filter: Class.new do
        def filter(opts)
          opts['resource'] = '[FILTERED]' if opts['resource'] && MR.env == 'production'
          opts
        end
      end.new
    }

    before do
      auth_required = ActiveRecord::Type::Boolean.new.deserialize(
        ENV.fetch('AUTHENTICATION_REQUIRED', nil)
      )

      authenticate! if auth_required && request.path != '/swagger.json'
    end

    mount API::V1::Base
    mount API::V2::Base
  end
end
