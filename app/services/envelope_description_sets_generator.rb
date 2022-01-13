class EnvelopeDescriptionSetsGenerator
  attr_reader :envelope

  def initialize(envelope:)
    @envelope = envelope
  end

  def generate!
    envelope_resources.flat_map do |resource|
      EnvelopeResourceDescriptionSetsGenerator.new(
        envelope_resource: resource,
      ).generate!
    end
  end

  def envelope_resources
    envelope.envelope_resources
  end

  class EnvelopeResourceDescriptionSetsGenerator
    attr_reader :envelope_resource

    def initialize(envelope_resource:)
      @envelope_resource = envelope_resource
    end

    def generate!
      delete_description_sets!

      if envelope_deleted?
        return
      end

      generate_description_sets!
    end

    def envelope_deleted?
      envelope.deleted_at.present?
    end

    def envelope
      envelope_resource.envelope
    end

    def delete_description_sets!
      delete_subject_description_sets!
      delete_target_description_sets!
    end

    def delete_subject_description_sets!
      DescriptionSet.where(ceterms_ctid: resource_id).destroy_all
    end

    def resource_id
      envelope_resource.resource_id
    end

    def delete_target_description_sets!
      existing_target_description_sets.find_each do |target_description_set|
        target_description_set.uris.delete(resource_uri)

        if target_description_set.uris.blank?
          target_description_set.destroy!
        else
          target_description_set.save!
        end
      end
    end

    def existing_target_description_sets
      @existing_target_description_sets ||= DescriptionSet.where("? = ANY(uris)", resource_uri)
    end

    def resource_uri
      ConvertBnodeToUri.call(resource_payload.fetch("@id"))
    end

    def resource_payload
      envelope_resource.processed_resource
    end

    def generate_description_sets!
      generate_subject_description_sets!
      generate_target_description_sets!
    end

    def generate_subject_description_sets!
      resource_type_maps.flat_map do |map|
        MapDescriptionSetsGenerator.new(
          envelope_resource: envelope_resource,
          map: map,
          reverse: false,
        ).generate!
      end
    end

    def resource_type_maps
      @resource_type_maps ||= maps.select do |map|
        map.fetch(:types).include?(resource_payload.fetch("@type"))
      end
    end

    def maps
      @maps ||= YAML.load_file(
        MR.root_path.join("fixtures", "description_set_item_maps.yml")
      )
    end

    def generate_target_description_sets!
      maps.flat_map do |map|
        MapDescriptionSetsGenerator.new(
          envelope_resource: envelope_resource,
          map: map,
          reverse: true,
        ).generate!
      end
    end

    class MapDescriptionSetsGenerator
      attr_reader :envelope_resource, :map, :reverse

      def initialize(envelope_resource:, map:, reverse:)
        @envelope_resource = envelope_resource
        @map = map
        @reverse = reverse
      end

      def generate!
        if description_sets.count == 0
          return
        end

        DescriptionSet.bulk_import(
          description_sets,
          on_duplicate_key_update: [
            :uris,
            :envelope_resource_id,
            :envelope_community_id,
          ]
        )
      end

      def description_sets
        @description_sets ||= result_bindings.map do |binding|
          subject = binding.dig("subject", "value")
          next if subject.include?("/graph/")

          resource_id = subject.split("/").last
          resource_id = "_:#{resource_id}" if subject.include?("/bnodes/")

          envelope_resource = EnvelopeResource.find_by_resource_id(resource_id)

          DescriptionSet.find_or_initialize_by(
            ceterms_ctid: resource_id,
            path: map.fetch(:path),
          ).tap do |description_set|
            description_set.uris |= binding.dig("uris", "value").split(" ")
            description_set.envelope_resource = envelope_resource
            description_set.envelope_community = envelope_resource.envelope_community
          end
        end.compact
      end

      def valid_sparql_response?
        sparql_response.status == 200
      end

      def sparql_response
        @sparql_response ||= QuerySparql.call(query: sparql_query)
      end

      def sparql_query
        variable = reverse ? "target" : "subject"

        subject_condition = <<~SPARQL
        BIND(<#{resource_uri}> AS ?#{variable})
        VALUES ?type { #{map.fetch(:types).join(" ")} }
        ?subject a ?type .
      SPARQL

      <<~SPARQL
        PREFIX asn: <http://purl.org/ASN/schema/core/>
        PREFIX ceasn: <https://purl.org/ctdlasn/terms/>
        PREFIX ceterms: <https://purl.org/ctdl/terms/>
        PREFIX credreg: <https://credreg.net/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

        SELECT ?subject (GROUP_CONCAT(DISTINCT ?target) AS ?uris)
        WHERE
        {
          #{subject_condition}
          #{map.fetch(:query)}
        }
        GROUP BY ?subject
      SPARQL
      end

      def resource_uri
        ConvertBnodeToUri.call(resource_payload.fetch("@id"))
      end

      def resource_payload
        envelope_resource.processed_resource
      end

      def result_bindings
        sparql_response.result.dig("results", "bindings")
      end
    end
  end
end
