require 'grape'
require 'active_record'
require 'active_support/concern'

module API
  module V1
    # Default options for all API endpoints and versions
    module Defaults
      extend ActiveSupport::Concern

      included do
        # Common Grape settings
        version 'v1', using: :accept_version_header
        format :json
        prefix :api

        # Global handler for simple not found case
        rescue_from ActiveRecord::RecordNotFound do |e|
          error_response(message: e.message, status: 404)
        end
      end
    end
  end
end
