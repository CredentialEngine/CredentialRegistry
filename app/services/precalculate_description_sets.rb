# Creates or updates description sets built from SPARQL data
class PrecalculateDescriptionSets
  class << self
    def process(envelope)
      envelope.processed_resource.fetch('@graph').each do |resource|
        ctid = resource['ceterms:ctid']
        next unless ctid.present?

        description_sets = maps
          .select { |m| m[:types].include?(resource.fetch('@type')) }
          .map do |map|
            build_description_sets(map, ctid)
          end.flatten

        insert_description_sets(description_sets)
      end
    end

    def process_all
      maps.each do |map|
        insert_description_sets(build_description_sets(map))
      end
    end

    private

    def build_description_sets(map, ctid = nil)
      path = map.fetch(:path)
      query = map.fetch(:query)
      types = map.fetch(:types)

      query = <<~SPARQL
        PREFIX ceasn: <https://purl.org/ctdlasn/terms/>
        PREFIX ceterms: <https://purl.org/ctdl/terms/>
        PREFIX credreg: <https://credreg.net/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

        SELECT ?ctid (GROUP_CONCAT(?target) AS ?uris)
        WHERE
        {
          #{"BIND('#{ctid}' AS ?ctid)" if ctid}
          VALUES ?type { #{types.join(' ')} }
          ?subject a ?type .
          ?subject ceterms:ctid ?ctid .
          #{query}
        }
        GROUP BY ?ctid
      SPARQL

      response = QuerySparql.call('query' => query)
      
      if response.status != 200
        MR.logger.error(
          "PrecalculateDescriptionSets -- Failed to execute query: #{query}"
        )

        return []
      end

      JSON(response.result).dig('results', 'bindings').map do |binding|
        description_set = DescriptionSet.find_or_initialize_by(
          ceterms_ctid: binding.dig('ctid', 'value'),
          path: path
        )

        description_set.uris = binding.dig('uris', 'value').split(' ')
        description_set
      end
    end

    def insert_description_sets(description_sets)
      DescriptionSet.bulk_import(
        description_sets,
        on_duplicate_key_update: [:uris]
      )
    end

    def maps
      @maps ||= YAML.load_file(
        MR.root_path.join('fixtures', 'description_set_item_maps.yml')
      )
    end
  end
end
