require 'description_set'
require 'entities/description_set_data'

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
          optional :include_resources, default: false, type: Boolean
          optional :path_contains, type: String
          optional :path_exact, type: String
          optional :per_branch_limit, type: Integer
        end
        post do
          description_sets = DescriptionSet
            .where(ceterms_ctid: params[:ctids])
            .select(:path)
            .select('cardinality(uris) total')

          if (path_exact = params[:path_exact]).present?
            description_sets.where!('LOWER(path) = ?', path_exact.downcase)
          elsif (path_contains = params[:path_contains]).present?
            description_sets.where!("path ILIKE '%#{path_contains}%'")
          end

          description_sets =
            if (limit = params[:per_branch_limit])
              description_sets.select("uris[1:#{limit}] uris")
            else
              description_sets.select(:uris)
            end

          resources =
            if params[:include_resources]
              ids = description_sets.map(&:uris).flatten.uniq.map do |uri|
                id = uri.split('/').last
                next id unless uri.starts_with?('https://credreg.net/bnodes/')

                "_:#{id}"
              end

              EnvelopeResource.where(resource_id: ids).pluck(:processed_resource)
            end

          result = OpenStruct.new(
            description_sets: description_sets,
            resources: resources
          )

          present result, with: API::Entities::DescriptionSetData
          status :ok
        end
      end
    end
  end
end
