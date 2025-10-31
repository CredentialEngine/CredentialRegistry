require 'v1/base'
require 'v2/base'
require_relative '../../lib/json_request_logger'

module API
  # Main base class that defines all API versions
  class Base < Grape::API
    # Emit a single JSON log line per request
    use JsonRequestLogger

    mount API::V1::Base
    mount API::V2::Base
  end
end
