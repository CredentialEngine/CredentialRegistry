require 'description_set'
require 'entities/description_set_data'
require 'fetch_description_set_data'

module API
  module V1
    class DescriptionSets < Grape::API
      before do
        authenticate!
      end

      resource :description_sets do
        desc 'Returns the description sets for the specified resource and paths'
        params do
          requires :ctid, regexp: /\A.+\z/, type: String
          optional :limit, type: Integer
          optional :path_contains, type: String
          optional :path_exact, type: String
        end
        get ':ctid' do
          sets = DescriptionSet
            .where(ceterms_ctid: params[:ctid])
            .select(:path)
            .select('cardinality(uris) total')
            .order(:path)

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
          optional :include_graph_data, default: false, type: Boolean
          optional :include_resources, default: false, type: Boolean
          optional :include_results_metadata, default: false, type: Boolean
          optional :path_contains, type: String
          optional :path_exact, type: String
          optional :per_branch_limit, type: Integer
        end
        post do
          options = params.symbolize_keys.slice(
            :include_graph_data,
            :include_resources,
            :include_results_metadata,
            :path_contains,
            :path_exact,
            :per_branch_limit
          )

          data = FetchDescriptionSetData.call(params[:ctids], **options)
          present data, with: API::Entities::DescriptionSetData
          status :ok
        end
      end
    end
  end
end
