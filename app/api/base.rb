require 'v1/base'
require 'v2/base'

module API
  # Main base class that defines all API versions
  class Base < Grape::API
    insert_after Grape::Middleware::Formatter, Grape::Middleware::Logger, {
      logger: MR.logger,
      filter: Class.new do
        def filter(opts)
          opts['resource'] = '[FILTERED]' if opts['resource'] && MR.env == 'production'
          opts
        end
      end.new
    }

    mount API::V1::Base
    mount API::V2::Base
  end
end
