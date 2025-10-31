require 'v1/base'
require 'v2/base'

module API
  # Main base class that defines all API versions
class Base < Grape::API
    # Normalize ActiveRecord not-found errors to a stable API message
    rescue_from ActiveRecord::RecordNotFound do |e|
      model = e.respond_to?(:model) && e.model ? e.model : 'Resource'
      error!({ errors: ["#{model} not found"] }, 404)
    end
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
