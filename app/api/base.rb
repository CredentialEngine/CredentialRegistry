require 'grape'
require_relative 'documents'

module API
  # Base class that gathers all the API endpoints
  class Base < Grape::API
    format :json
    prefix :api

    mount API::Documents
  end
end
