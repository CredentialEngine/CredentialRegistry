require 'open-uri'
require_relative '../../config/environment'
require_relative '../../lib/neo4j_helper'

# Creates a node in Neo4j as well as its relations from a given JSON document, specified by a
# string, a Ruby Hash object or a remote URL.
class Neo4jImport
  include Neo4jHelper

  attr_reader :json_document, :query

  def initialize(json_resource)
    @query = Neo4j::Session.query
    @json_document = json_resource.is_a?(Hash) ? json_resource : JSON.parse(json_resource)
  rescue JSON::ParserError
    @json_document = begin
      JSON.parse(open(json_resource).read)
    rescue OpenURI::HTTPError
      MR.logger.error "Document could not be retrieved from '#{json_resource}'"
      {}
    end
  end

  def create
    return :unavailable_document if json_document.empty?

    log_doc_details
    parent_node = create_node
    create_relations(parent_node)

    parent_node
  end

  private

  def id(object = json_document)
    object['@id']
  end

  def id?(object = json_document)
    object.key?('@id')
  end

  def log_doc_details
    message = if id?
                "Importing top-level document of type '#{type}' with @id '#{json_document['@id']}'"
              else
                "Importing embedded document of type '#{type}'"
              end
    MR.logger.info message
  end

  def create_node
    node = if id?
             query.merge(build_attributes(id: id)).on_create_set(doc: literals)
           else
             query.create(build_attributes(literals))
           end
    node.pluck(:doc).last
  end

  def build_attributes(values)
    { doc: {} }.tap do |attributes|
      attributes[:doc][type.to_sym] = values
    end
  end

  def create_relations(node)
    objects.each do |key, object|
      if object.is_a?(Array)
        object.each { |nested_object| build_relation(node, key, nested_object) }
      else
        build_relation(node, key, object)
      end
    end
  end

  def literals(object = json_document)
    literal_props = {}
    object.each do |key, value|
      literal_props[key] = value if literal?(value)
      literal_props[key] = value['@id'] if literal_id?(value)
    end
    cleanup(literal_props)
  end

  def objects
    related_objects = {}
    json_document.each do |key, value|
      related_objects[key] = value if !literal?(value) && !literal_id?(value)
    end
    cleanup(related_objects)
  end

  def type(node = json_document)
    normalize(node['@type']) || 'GenericObject'
  end

  def literal?(value)
    !value.respond_to?(:each) || !value.first.respond_to?(:each)
  end

  def literal_id?(object)
    object.is_a?(Hash) && id?(object) && !valid_origin?(object['@id'])
  end

  def build_relation(parent_node, key, object)
    if id?(object) && valid_origin?(id(object))
      retrieved_node = node_by_id(id(object)) || Neo4jImport.new(id(object)).create
      if retrieved_node != :unavailable_document
        parent_node.create_rel(key, retrieved_node) unless relation_exists?(parent_node, key)
      end
    else
      retrieved_node = Neo4jImport.new(object).create
      parent_node.create_rel(key, retrieved_node)
    end
  end
end
