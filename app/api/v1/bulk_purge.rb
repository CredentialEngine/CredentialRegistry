module API
  module V1
    # Purges a given publisher's envelopes
    class BulkPurge < MountableAPI
      mounted do
        helpers CommunityHelpers

        resource :envelopes do
          before do
            authenticate!
          end

          desc "Purges a given publisher's envelopes"
          params do
            optional :owned_by, type: String
            optional :published_by, type: String
            optional :resource_type, type: String
            optional :from, type: DateTime
            optional :until, type: DateTime
            at_least_one_of :owned_by, :published_by
          end
          delete do
            owner =
              if (owned_by = params[:owned_by])
                Organization.find_by!(_ctid: owned_by)
              end

            publisher =
              if (published_by = params[:published_by])
                Organization.find_by!(_ctid: published_by)
              end

            envelopes = Envelope.in_community(select_community)

            if owner
              envelopes = envelopes.where(organization: owner)
            end

            if publisher
              envelopes = envelopes.where(publishing_organization: publisher)
            end

            if params[:resource_type]
              envelopes = envelopes.where(resource_type: params[:resource_type])
            end

            if params[:from]
              envelopes = envelopes.where(
                'envelopes.created_at >= ?',
                params[:from]
              )
            end

            if params[:until]
              envelopes = envelopes.where(
                'envelopes.created_at <= ?',
                params[:until]
              )
            end

            { purged: envelopes.delete_all }
          end
        end
      end
    end
  end
end
