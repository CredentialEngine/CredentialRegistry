# Inserts pre-calculated description set statements into the SPARQL DB
class PrecalculateDescriptionSets
  class << self
    def process(envelope)
      envelope.processed_resource.fetch('@graph').each do |resource|
        type = resource.fetch('@type')
        items = maps[type]
        next unless items

        insert_description_set(resource.fetch('@id'), items)
      end
    end

    def process_all
      maps.each do |type, items|
        EnvelopeResource.where(resource_type: type).find_each do |resource|
          uri = resource.processed_resource.fetch('@id')
          insert_description_set(uri, items)
        end
      end
    end

    private

    def insert_description_set(uri, items)
      conditions = []
      nodes = []

      items.each_with_index do |item, index|
        target = "?target#{index + 1}"
        conditions << "{ #{item[:query].gsub('?target', target)} }"

        nodes << <<~NODE
          credreg:__relatedItemsMap [
            credreg:__dspPath '#{item[:path]}';
            credreg:__dspURI #{target}
          ]
        NODE
      end

      statement = <<~SPARQL
        PREFIX ceasn: <https://purl.org/ctdlasn/terms/>
        PREFIX ceterms: <https://purl.org/ctdl/terms/>
        PREFIX credreg: <https://credreg.net/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

        INSERT
        {
          ?subject credreg:__descriptionSet [
            #{nodes.join(";\n")}
          ]
        }
        WHERE
        {
          VALUES ?subject { <#{uri}> }
          #{conditions.join("\nUNION\n")}
        }
      SPARQL

      QuerySparql.call('update' => statement)
    end

    def maps
      @maps ||= YAML.load_file(
        MR.root_path.join('fixtures', 'description_set_item_maps.yml')
      )
    end
  end
end
