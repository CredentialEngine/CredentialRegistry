require 'mountable_api'
require 'description_set'
require 'fetch_description_set_data'
require 'entities/description_set_data'
require 'helpers/shared_helpers'
require 'helpers/community_helpers'
require 'policies/envelope_resource_policy'

module API
  module V1
    class DescriptionSets < MountableAPI # rubocop:todo Style/Documentation
      mounted do # rubocop:todo Metrics/BlockLength
        helpers SharedHelpers
        helpers CommunityHelpers

        include API::V1::Defaults

        before do
          authenticate!
          params[:envelope_community] = select_community if params[:envelope_community].blank?
        end

        before_validation { normalize_envelope_community }

        resource :description_sets do
          desc 'Returns the description sets for the specified resource and paths'
          params do
            requires :ctid, regexp: /\A.+\z/, type: String
            optional :limit, type: Integer
            optional :path_contains, type: String
            optional :path_exact, type: String
          end
          get ':ctid' do
            authorize EnvelopeResource, :index?

            envelope_community = EnvelopeCommunity.find_by(name: community)

            sets = DescriptionSet
                   .where(envelope_community: envelope_community)
                   .where(ceterms_ctid: params[:ctid])
                   .select(:path)
                   .select('cardinality(uris) total')
                   .order(Arel.sql('path COLLATE "C"'))

            if (path_exact = params[:path_exact]).present?
              sets.where!('LOWER(path) = ?', path_exact.downcase)
            elsif (path_contains = params[:path_contains]).present?
              sets.where!("path ILIKE '%#{path_contains}%'")
            end

            sets =
              if (limit = params[:limit])
                sets.select("uris[1:#{limit}] uris")
              else
                sets.select(:uris)
              end

            present sets, with: API::Entities::DescriptionSet
          end

          desc 'Returns the description sets for the specified CTIDs and paths'
          params do
            requires :ctids, type: Array
            optional :include_graph_data, default: false, type: Grape::API::Boolean
            optional :include_resources, default: false, type: Grape::API::Boolean
            optional :include_results_metadata, default: false, type: Grape::API::Boolean
            optional :path_contains, type: String
            optional :path_exact, type: String
            optional :per_branch_limit, type: Integer
          end
          post do
            authorize EnvelopeResource, :index?

            options = params.symbolize_keys.slice(
              :include_graph_data,
              :include_resources,
              :include_results_metadata,
              :path_contains,
              :path_exact,
              :per_branch_limit
            )

            data = FetchDescriptionSetData.call(
              params[:ctids],
              envelope_community: current_user_community,
              **options
            )

            present data, with: API::Entities::DescriptionSetData
            status :ok
          end
        end
      end
    end
  end
end
