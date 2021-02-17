require 'mountable_api'
require 'envelope'
require 'delete_token'
require 'batch_delete_envelopes'
require 'envelope_builder'
require 'entities/envelope'
require 'helpers/shared_helpers'
require 'helpers/community_helpers'
require 'helpers/envelope_helpers'
require 'v1/single_envelope'
require 'v1/revisions'

module API
  module V1
    # Implements all the endpoints related to envelopes
    class Envelopes < MountableAPI
      mounted do # rubocop:disable Metrics/BlockLength
        include API::V1::Defaults

        helpers SharedHelpers
        helpers EnvelopeHelpers
        helpers CommunityHelpers

        before do
          params[:envelope_community] = select_community if params[:envelope_community].blank?
        end

        before_validation { normalize_envelope_community }

        desc 'Show metadata community'
        get 'community' do
          EnvelopeCommunity.find_by!(name: community).as_json
        end

        desc 'Gives general info about the community'
        get 'community/info' do
          comm = EnvelopeCommunity.find_by!(name: community)
          {
            total_envelopes: comm.envelopes.count,
            backup_item: comm.backup_item
          }
        end

        resource :envelopes do
          desc 'Retrieves all envelopes ordered by date', is_array: true
          params { use :pagination }
          paginate max_per_page: 200
          get do
            authenticate_community!
            envelopes = paginate find_envelopes.ordered_by_date
            present envelopes, with: API::Entities::Envelope
          end

          desc 'Sends all envelope payloads in a ZIP archive'
          get :download do
            authenticate!

            file = Tempfile.new
            filename = "#{community}_#{Time.current.to_i}.zip"

            Zip::OutputStream.open(file.path) do |stream|
              find_envelopes.find_each do |envelope|
                stream.put_next_entry("#{envelope.envelope_id}.json")
                stream.puts(envelope.processed_resource.to_json)
              end
            end

            content_type 'application/zip'
            env['api.format'] = :binary
            header['Content-Disposition'] = "attachment; filename=#{filename}"
            file.read
          end

          desc 'Publishes a new envelope',
               http_codes: [
                 { code: 201, message: 'Envelope created' },
                 { code: 200, message: 'Envelope updated' }
               ]
          params do
            optional :owned_by, type: String
            optional :published_by, type: String
            use :update_if_exists
            use :skip_validation
          end
          post do
            if (owned_by = params[:owned_by]).present?
              params[:organization_id] = Organization.find_by!(_ctid: owned_by).id
            end

            if (published_by = params[:published_by]).present?
              params[:publishing_organization_id] = Organization
                .find_by!(_ctid: published_by)
                .id
            end

            envelope, errors = EnvelopeBuilder.new(
              params,
              update_if_exists: update_if_exists?,
              skip_validation: skip_validation?
            ).build

            if errors
              json_error! errors, [:envelope, envelope.try(:resource_schema_name), :json_ld]
            else
              present envelope, with: API::Entities::Envelope
              update_if_exists? ? status(:ok) : status(:created)
            end
          end

          desc 'Marks envelopes matching a resource locator as deleted'
          helpers do
            def validate_delete_envelope_json
              validator = JSONSchemaValidator.new(params, :delete_envelope)
              return unless validator.invalid?

              json_error! validator.error_messages, :delete_envelope
            end

            def find_community_envelopes
              envelopes = find_envelopes.where(envelope_id: params[:envelope_id])
              if envelopes.empty?
                err = ['No matching envelopes found']
                json_error! err, :delete_envelope, :not_found
              end
              envelopes
            end
          end
          put do
            validate_delete_envelope_json
            envelopes = find_community_envelopes
            BatchDeleteEnvelopes.new(envelopes, DeleteToken.new(params)).run!

            body false
            status :no_content
          end

          desc 'Gives general info about the envelopes'
          get(:info) { envelopes_info }

          route_param :envelope_id do
            after_validation do
              id = params[:envelope_id]

              @envelope = find_envelopes.find_by(envelope_id: id) ||
                find_envelopes.where(envelope_ceterms_ctid: id).last

              if @envelope.nil?
                error!({ errors: ['Couldn\'t find Envelope'] }, 404)
              end
            end

            include API::V1::SingleEnvelope
            include API::V1::Revisions
          end
        end
      end
    end
  end
end
