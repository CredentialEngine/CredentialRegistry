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
          error!({ errors: Array(e.message) }, 404)
        end

        # Global handler for validation errors
        rescue_from Grape::Exceptions::ValidationErrors do |e|
          error!({ errors: e.full_messages }, 400)
        end

        # Global handler for application specific errors
        rescue_from MetadataRegistry::BaseError do |e|
          error!({ errors: e.errors }, 400)
        end

        # Global handler for decoding/signing errors
        rescue_from OpenSSL::PKey::RSAError,
                    JWT::DecodeError,
                    JWT::VerificationError do |e|
          error!({ errors: Array(e.message) }, 400)
        end

        # Global handler for any unexpected exception
        rescue_from :all do |e|
          error!({ errors: Array(e.message) }, 500)
        end
      end
    end
  end
end
