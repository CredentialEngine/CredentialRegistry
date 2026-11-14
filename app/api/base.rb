require 'grape_logging'
require 'v1/base'
require 'v2/base'

module API
  # Main base class that defines all API versions
  class Base < Grape::API
    helpers CommunityHelpers

    # Request logging with production-only payload redaction.
    # The logger must wrap Grape's error middleware to observe final statuses.
    request_loggers = []
    if MR.env == 'production'
      request_loggers << GrapeLogging::Loggers::FilterParameters.new(['resource'])
    end

    insert_before Grape::Middleware::Error,
                  GrapeLogging::Middleware::RequestLogger,
                  logger: MR.logger,
                  include: request_loggers

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
