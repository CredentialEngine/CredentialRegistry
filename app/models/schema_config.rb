require 'erb'

# Community/Type Schema config.
# Given a schema_name, it builds both the json-schema and the config
# from the matching `.json` files.
# I.e:
#
#  >> SchemaConfig.new('my_community/bla').json_schema
#     # parse schema from '*/schema/my_community/bla/schema.json.erb'
#
#  >> SchemaConfig.new('my_community/bla').config
#     # parse config from '*/schema/my_community/bla/config.json'
class SchemaConfig
  include ERB::Util

  attr_reader :name, :prefix

  # Params:
  #  - name: [String|Symbol] schema name, corresponds to the json files path
  #  - prefix: [Symbol] used for rendering embeded partial, determine the
  #                     context namespace (if any) for the properties.
  #                     i.e: if prefix=bla then: "<%=prop 'abc' %>" => "bla:abc"
  def initialize(name, prefix = nil)
    @name = name.to_s
    @prefix = prefix
  end

  # resolve file paths for the corresponding schema name
  # Return: [String]
  def base_path
    @base_path ||= File.expand_path('../../schemas/', __FILE__)
  end

  # Parse rendered config json
  # Return: [Hash] the resulting config
  def config
    @config ||= begin
      community, type = name.split('/')
      content = File.read(base_path + "/#{community}/config.json")
      config = JSON.parse(content)
      type.present? ? config[type] : config
    end
  rescue Errno::ENOENT
    raise MR::SchemaDoesNotExist, name
  end

  # Parsed json-schema
  # If you provide a request param, then we transform the rendered schema to
  # have public urls instead of file paths on the refs. This is used to return
  # schemas on the API
  #
  # Params:
  #  - req: [Rack::Request] the http request for this public schema
  # Return: [Hash] the resulting schema
  def json_schema(req = nil)
    if req
      @public_schema ||= JSON.parse rendered_schema_public(req)
    else
      @json_schema ||= JSON.parse rendered_schema
    end
  end

  # Return: [String] Rendered ERB template
  def rendered_schema
    @rendered_schema ||= begin
      template = File.read(schema_file_path.to_s)
      ERB.new(template).result(binding)
    rescue Errno::ENOENT
      raise MR::SchemaDoesNotExist, "Schema for #{name} does not exist"
    end
  end

  # Rendered ERB template with replaced refs
  def rendered_schema_public(req)
    rendered_schema.gsub(
      # from: "$ref": "app/schemas/json_ld.json.erb"
      %r{\"\$ref\": \"app/schemas/(.*)\.json\.erb\"},
      # to:   "$ref": "http://myurl.com/api/schemas/json_ld"
      "\"$ref\": \"#{req.base_url}/api/schemas/\\1\""
    )
  end

  def schema_file_path
    # if we have name='something', then it will try to find the first schema
    # file, on the following paths, that exists:
    #   schemas/something.json.erb
    #   schemas/something/schema.json.erb
    @schema_file_path ||= [
      base_path + "/#{name}.json.erb",
      base_path + "/#{name}/schema.json.erb"
    ].select { |path| File.exist?(path) }.first
  end

  # Tell if the corresponding schema template exists
  # Return: [Boolean]
  def schema_exist?
    schema_file_path.present?
  end

  # ERB helper for rendering a embeded/partial json schema definition
  # Return: [String] rendered 'partial'
  def partial(name, prefix = nil)
    self.class.new(name, prefix).rendered_schema
  end

  # ERB helper for properties names that might be namespaced.
  # I.e:
  #   "<%=prop 'something' %>", where prefix='abc' => "abc:something"
  #
  def prop(key)
    prefix ? "#{prefix}:#{key}" : key
  end

  # ERB helper for building refs with proper relative path, used for internal
  # schema validation. The public schema parse this to a public url
  def ref(name)
    "app/schemas/#{name}.json.erb"
  end

  # List of all available configs
  #
  # Return: [List[String]] list of schema names
  def self.all_configs
    Dir['app/schemas/**/*.json']
      .select { |path| !path.split('/').last.start_with?('_') }
      .map    { |path| path.match(%r{app/schemas/(.*)/config.json})[1] }
  end

  # List of all available schemas
  #
  # Return: [List[String]] list of schema names
  def self.all_schemas
    Dir['app/schemas/**/*.json.erb']
      .select { |path| !path.split('/').last.start_with?('_') }
      .map    { |path| path.match(%r{app/schemas/(.*).json.erb})[1] }
      .map    { |path| path.gsub(%r{/schema$}, '') }
  end

  # get the resource_type for the envelope from the community config (if exists)
  # Ex:
  #   1) resource_type is a string
  #   config: {"resource_type": "@type"}
  #   processed_resource: "@type"='Bla'
  #   >> 'Bla'
  #
  #   2) resource_type is an object with mapped values
  #   config: {"resource_type": {
  #             "property": "@type", "values_map": {"abc:Bla": 'bla'}
  #            }}
  #   processed_resource: "@type"='abc:Bla'
  #   >> 'bla'
  def self.resource_type_for(envelope)
    cfg = new(envelope.community_name).config.try(:[], 'resource_type')
    return nil if cfg.blank?

    if cfg.is_a?(String)
      envelope.processed_resource[cfg]
    else
      get_resource_type_from_values_map(envelope, cfg)
    end
  end

  def self.get_resource_type_from_values_map(envelope, cfg)
    key = envelope.processed_resource[cfg['property']]
    raise "The property #{cfg['property']} is required" unless key
    cfg['values_map'][key]
  end
end
