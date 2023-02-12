require 'convert_bnode_to_uri'
require 'nonascii_friendly_uri'
require 'rdf_node'
require 'tokenize_rdf_data'

# Converts JSON-LD payloads into RDF format and uploads into Amazon Neptune
class RdfIndexer
  CREATED_PROPERTY = 'https://credreg.net/__createdAt'.freeze
  GRAPH_PROPERTY = 'https://credreg.net/__graph'.freeze
  OWNED_BY_PROPERTY = 'https://credreg.net/__recordOwnedBy'.freeze
  PAYLOAD_PROPERTY = 'https://credreg.net/__payload'.freeze
  PUBLISHED_BY_PROPERTY = 'https://credreg.net/__recordPublishedBy'.freeze
  ROOT_PROPERTY = 'https://credreg.net/__root'.freeze
  UPDATED_PRORERTY = 'https://credreg.net/__updatedAt'.freeze

  class << self
    def clear_all
      logger.info 'Clearing all data…'
      QuerySparql.call(update: 'CLEAR ALL')
      logger.info 'Cleared data successfully.'
    rescue => e
      logger.error "Failed to clear data -- #{e.message}"
    end

    def delete(envelope)
      command = 'DELETE WHERE { ?s ?p ?o . ?s <%{property}> <%{id}> }' % {
        id: parent_resource_id(envelope),
        property: ROOT_PROPERTY
      }

      logger.info "Deleting envelope ##{envelope.id}, command: #{command}"
      QuerySparql.call(update: command)
      logger.info "Deleting envelope ##{envelope.id} successfully."
    rescue => e
      logger.error "Failed to delete envelope ##{envelope.id} -- #{e.message}"
    end

    def exists?(envelope)
      query = 'SELECT ?s WHERE { ?s <%{property}> <%{id}> }' % {
        id: parent_resource_id(envelope),
        property: ROOT_PROPERTY
      }

      QuerySparql.call(query: query).result.dig('results', 'bindings').any?
    end

    def generate_nquads(envelope)
      owner = envelope.organization
      publisher = envelope.publishing_organization
      resource = envelope.processed_resource
      return [] unless resource['@graph']

      resource = bnodes2uris(resource)
      graph_id = RDF::URI.new(resource.fetch('@id'))
      root_id = RDF::URI.new(parent_resource_id(envelope))

      graph = RDF::Graph.new
      graph << JSON::LD::API.toRdf(resource)
      graph << [graph_id, RDF::URI.new(CREATED_PROPERTY), RDF::Literal::DateTime.new(envelope.created_at)]
      graph << [graph_id, RDF::URI.new(UPDATED_PRORERTY), RDF::Literal::DateTime.new(envelope.updated_at)]
      graph << [root_id, RDF::URI.new(GRAPH_PROPERTY), graph_id]

      resource['@graph'].each do |resource|
        id = resource['@id']
        next unless id.starts_with?('http')

        graph << [RDF::Resource.new(id), RDF::URI.new(PAYLOAD_PROPERTY), resource.to_json]

        if owner
          graph << [RDF::Resource.new(id), RDF::URI.new(OWNED_BY_PROPERTY), owner._ctid]
        end

        if publisher
          graph << [RDF::Resource.new(id), RDF::URI.new(PUBLISHED_BY_PROPERTY), publisher._ctid]
        end
      end

      graph.subjects.each do |subject|
        graph << [subject, RDF::URI.new(ROOT_PROPERTY), root_id]
      end

      graph.each do |statement|
        object = statement.object
        next unless object.respond_to?(:language) && object.language.present?

        graph << [statement.subject, RDF::URI.new("#{statement.predicate.value}__plaintext"), object.value]
      end

      TokenizeRdfData.call(graph)

      graph.dump(:nquads).split("\n").sort
    rescue => e
      logger.error "Failed to generate N-Quads for envelope ##{envelope.id} -- #{e.message}"
      []
    end

    def index(envelope)
      logger.info "Indexing envelope ##{envelope.id}…"
      file = Tempfile.new
      nquads = generate_nquads(envelope)
      file.write(nquads.join("\n"))
      file.rewind
      s3_path = upload_to_s3(file, "envelope_#{envelope.id}")
      delete(envelope)
      upload_to_neptune(s3_path)
      logger.info "Indexed envelope ##{envelope.id} successfully."
    rescue => e
      logger.error "Failed to index envelope ##{envelope.id} -- #{e.message}"
    ensure
      file.delete
    end

    def index_all
      logger.info "Indexing all envelopes…"
      file = Tempfile.new

      envelopes = Envelope
        .not_deleted
        .includes(:organization, :publishing_organization)

      envelopes.find_each do |envelope|
        nquads = generate_nquads(envelope)
        file.write(nquads.join("\n"))
        file.write("\n")
      end

      file.rewind
      s3_path = upload_to_s3(file, 'all')
      clear_all
      upload_to_neptune(s3_path)
      logger.info "Indexing all envelopes successfully."
    rescue => e
      logger.error "Failed to index all envelopes -- #{e.message}"
    ensure
      file.delete
    end

    def upload_to_neptune(s3_path)
      logger.info "Uploading #{s3_path} to Neptune…"

      uri = URI(neptune_endpoint)
      uri.path = '/loader'

      response = RestClient.post(
        uri.to_s,
        source: s3_path,
        format: 'nquads',
        iamRoleArn: ENV.fetch('NEPTUNE_DATA_ROLE'),
        region: aws_region,
        failOnError: 'TRUE',
        parallelism: 'MEDIUM',
        updateSingleCardinalityProperties: 'FALSE'
      )

      load_id = JSON(response.body).dig('payload', 'loadId')
      await_neptune_load_completion(load_id)
      logger.info "Uploaded #{s3_path} to Neptune successfully."
    rescue => e
      logger.error "Failed to upload #{s3_path} to Neptune -- #{e.message}"
    end

    def upload_to_s3(file, name)
      timestamp = Time.current.strftime('%Y-%m-%d-%H-%M-%S')
      key = "#{name}_#{timestamp}.nq"

      Aws::S3::Resource.new(region: aws_region)
        .bucket(bucket)
        .object(key)
        .upload_file(file)

      "s3://#{bucket}/#{key}"
    rescue => e
    end

    private

    def await_neptune_load_completion(load_id)
      uri = URI(neptune_endpoint)
      uri.path = "/loader/#{load_id}"

      loop do
        sleep 30.seconds
        logger.info "Checking status of upload #{load_id}"
        response = RestClient.get(uri.to_s)
        body = JSON(response.body)
        logger.info "Status of upload #{load_id} -- #{body}"
        return if body.dig('payload', 'feedCount', 0, 'LOAD_COMPLETED')
      end
    rescue => e
      logger.error "Failed to check status of upload #{load_id} -- #{e.message}"
    end

    def aws_region
      ENV.fetch('AWS_REGION')
    end

    def bnodes2uris(payload)
      if payload.is_a?(Array)
        payload.map { |item| bnodes2uris(item) }
      elsif payload.is_a?(Hash)
        payload.map { |k, v| [k, bnodes2uris(v)] }.to_h
      else
        ConvertBnodeToUri.call(payload)
      end
    end

    def bucket
      ENV.fetch('NEPTUNE_DATA_BUCKET')
    end

    def logger
      Logger.new(MR.root_path.join('log', 'rdf_indexer.log'))
    end

    def neptune_endpoint
      ENV.fetch('NEPTUNE_ENDPOINT')
    end

    def parent_resource_id(envelope)
      envelope.processed_resource.dig('@graph', 0, '@id')
    end
  end
end
