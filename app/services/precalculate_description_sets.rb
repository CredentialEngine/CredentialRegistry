require 'convert_bnode_to_uri'

# Creates or updates description sets built from SPARQL data
class PrecalculateDescriptionSets
  class << self
    def process(envelope)
      envelope.processed_resource.fetch('@graph', []).each do |resource|
        resource_id = resource.fetch('@id')

        description_sets = maps
          .select { |m| m[:types].include?(resource.fetch('@type')) }
          .map { |map| build_description_sets(map, resource_id) }
          .flatten

        description_sets += maps
          .map { |map| build_description_sets(map, resource_id, reverse: true) }
          .flatten

        insert_description_sets(description_sets)
      end
    end

    def process_all
      maps.each do |map|
        insert_description_sets(build_description_sets(map))
      end
    end

    private

    def build_description_sets(map, resource_id = nil, reverse: false)
      path = map.fetch(:path)
      query = map.fetch(:query)
      types = map.fetch(:types)

      subject_condition =
        if resource_id
          variable = reverse ? 'target' : 'subject'
          "BIND(<#{ConvertBnodeToUri.call(resource_id)}> AS ?#{variable})"
        else
          <<~SPARQL
            VALUES ?type { #{types.join(' ')} }
            ?subject a ?type .
          SPARQL
        end

      query = <<~SPARQL
        PREFIX asn: <http://purl.org/ASN/schema/core/>
        PREFIX ceasn: <https://purl.org/ctdlasn/terms/>
        PREFIX ceterms: <https://purl.org/ctdl/terms/>
        PREFIX credreg: <https://credreg.net/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

        SELECT ?subject (GROUP_CONCAT(DISTINCT ?target) AS ?uris)
        WHERE
        {
          #{subject_condition}
          #{query}
        }
        GROUP BY ?subject
      SPARQL

      response = QuerySparql.call('query' => query)

      if response.status != 200
        MR.logger.error(
          "PrecalculateDescriptionSets -- Failed to execute query: #{query}"
        )

        return []
      end

      JSON(response.result).dig('results', 'bindings').map do |binding|
        subject = binding.dig('subject', 'value')
        next if subject.include?('/graph/')

        resource_id = subject.split('/').last
        resource_id = "_:#{resource_id}" if subject.include?('/bnodes/')

        description_set = DescriptionSet.find_or_initialize_by(
          ceterms_ctid: resource_id,
          path: path
        )

        description_set.uris |= binding.dig('uris', 'value').split(' ')
        description_set
      end.compact
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
