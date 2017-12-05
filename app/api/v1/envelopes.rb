require 'envelope'
require 'delete_token'
require 'batch_delete_envelopes'
require 'envelope_builder'
require 'entities/envelope'
require 'helpers/shared_helpers'
require 'helpers/envelope_helpers'
require 'v1/single_envelope'
require 'v1/revisions'
require 'v1/envelope_api'

module API
  module V1
    # Implements all the endpoints related to envelopes
    class Envelopes < Grape::API
      include API::V1::EnvelopeAPI
    end
  end
end
