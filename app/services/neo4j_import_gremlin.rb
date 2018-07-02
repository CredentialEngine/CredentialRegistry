require 'active_support'
require 'set'
require 'digest/md5'

# Imports the Credential Registry's resources into a Neo4j database.
# The database will be exposed via Gremlin server.
class Neo4jImportGremlin
  class << self
    # Bulk import works by first going through all the envelopes and their inner
    # payloads and creating nodes.
    # As nodes are created, we keep track of relationships in a separate object.
    # This allows us to batch relationship creation when a node has more
    # than one edge.
    # Once all the nodes have been created, we commit the relationships.
    def bulk_import(session = Neo4j::Session.current!)
      Neo4j::Transaction.run(session) do
        edges = Edges.new(session)

        Envelope.order(created_at: :asc).find_each do |envelope|
          MR.logger.info("Adding vertex for envelope ID #{envelope.id}")
          Vertex.new(session, envelope.processed_resource, edges).save
        end

        edges.save
      end
    end
  end

  # Batches edge creation.
  class Edges
    attr_reader :session

    def initialize(session)
      @session = session
      @edges = {}
      @errors = []
    end

    def push(n1_id, type, n2_id)
      key = [n1_id, type]
      edges[key] ||= Set.new
      edges[key] << n2_id
      true
    end

    def save
      edges.each do |(n1_id, type), n2_ids|
        n2_ids = n2_ids.to_a
        rel_log = "(#{n1_id})-[#{type}]-(#{n2_ids.join(',')})"
        MR.logger.info("Creating relationships for #{rel_log}")

        count = create_edge(n1_id, type, n2_ids)

        MR.logger.error("Couldn't create relationship for #{rel_log} ") if count != n2_ids.count
      end
    end

    private

    attr_reader :edges

    def create_edge(n1_id, type, n2_ids)
      query = <<~CYPHER
        MATCH (a:Resource)
        WHERE a.id = {n1_id}
        WITH a
        MATCH (b:Resource)
        WHERE b.id in {n2_ids}
        MERGE (a)-[r:`#{type}`]->(b)
        RETURN COUNT(r) AS c
      CYPHER

      session.query(query, n1_id: n1_id, n2_ids: n2_ids).first.c
    end
  end

  # A Neo4j vertex.
  class Vertex
    attr_reader :session, :json_resource, :node, :edges, :id

    def initialize(session, json_resource, edges)
      @session = session
      @json_resource = json_resource
      @edges = edges
    end

    def label
      @label ||= self.class.normalize_prop(json_resource['@type']).to_sym
    end

    def save
      update_attrs = node_resource.except(:id)
      @node = session.query
                     .merge(n: { [label, :Resource] => { id: id } })
                     .set(n: update_attrs)
                     .pluck(:n)
                     .first
    end

    private

    class << self
      def array_literal?(value)
        value.is_a?(Array) && value.count.positive? && literal?(value[0])
      end

      def literal?(value)
        value.is_a?(String) \
          || value.is_a?(Numeric) \
          || [true, false].include?(value) \
          || value.nil?
      end

      def normalize_prop(val)
        val.tr(':-', '_').tr('@', '').to_sym
      end

      def generate_id(hash)
        digest = Digest::MD5.hexdigest(Marshal.dump(hash.sort))
        "generated:#{digest}"
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def node_resource
      @node_resource ||= begin
        node_res = ActiveSupport::OrderedHash.new
        new_edges = []
        json_resource.each do |key, value|
          if self.class.literal?(value)
            node_res[self.class.normalize_prop(key)] = value
          elsif self.class.array_literal?(value)
            node_res[self.class.normalize_prop(key)] = value.sort
          elsif value.is_a?(Array)
            value.each { |val| new_edges << get_relationship(key, val) }
          else # Val is a hash
            new_edges << get_relationship(key, value)
          end
        end
        node_res[:id] = self.class.generate_id(node_res) if node_res[:id].blank?
        @id = node_res[:id]
        node_res.delete(:type)
        new_edges.each { |(type, other_id)| edges.push(id, type, other_id) }
        node_res.to_h
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def get_relationship(type, other)
      other_id = \
        if other['@id'].present?
          other['@id']
        else
          other_node = self.class.new(session, other, edges)
          other_node.save
          other_node.id
        end

      [type, other_id]
    end
  end
end
