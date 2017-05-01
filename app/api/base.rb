require 'v1/base'

module API
  # Main base class that defines all API versions
  class Base < Grape::API
    insert_after Grape::Middleware::Formatter, Grape::Middleware::Logger, {
      logger: Logger.new("log/#{MR.env}.log"),
      filter: Class.new do
        def filter(opts)
          if opts['resource'] && MR.env == 'production'
            opts['resource'] = '[FILTERED]'
          end
          opts
        end
      end.new
    }

    mount API::V1::Base
  end
end
