require 'description_set'
require 'entities/description_set'

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
      end
    end
  end
end
