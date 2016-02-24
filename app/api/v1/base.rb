require_relative 'defaults'
require_relative 'documents'

module API
  module V1
    # Base class that gathers all the API endpoints
    class Base < Grape::API
      include API::V1::Defaults

      mount API::V1::Documents
    end
  end
end
