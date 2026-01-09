module API
  # Default options for all API endpoints and versions
  module Defaults
    extend ActiveSupport::Concern

    included do
      # Common Grape settings
      format :json

      # Global handler for invalid records
      rescue_from ActiveRecord::RecordInvalid do |e|
        error!(e.record.errors.full_messages.first, 422)
      end

      # Global handler for simple not found case
      rescue_from ActiveRecord::RecordNotFound do |e|
        log_backtrace(e)

        model = e.respond_to?(:model) && e.model ? e.model : 'Record'
        error!({ errors: ["#{model} not found"] }, 404)
      end

      # Global handler for validation errors
      rescue_from Grape::Exceptions::ValidationErrors do |e|
        error!({ errors: e.full_messages }, 400)
      end

      # Global handler for application specific errors
      rescue_from MetadataRegistry::BaseError do |e|
        log_backtrace(e)
        error!({ errors: e.errors || Array(e.message) }, 400)
      end

      # Global handler for decoding/signing errors
      rescue_from OpenSSL::PKey::RSAError,
                  JWT::DecodeError,
                  JWT::VerificationError do |e|
        log_backtrace(e)
        error!({ errors: Array(e.message) }, 400)
      end

      # Global handler for authorization errors
      rescue_from Pundit::NotAuthorizedError do
        error!('You are not authorized to perform this action', 403)
      end

      # Global handler for any unexpected exception
      rescue_from :all do |e|
        env['rack.exception'] = e # Store it in Rack env for Airbrake middleware
        log_backtrace(e)
        error!({ errors: Array(e.message) }, 500)
      end
    end
  end
end
