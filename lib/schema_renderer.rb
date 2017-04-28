require 'erb'

# Community/Type Schema config.
# Given a schema_name, it builds the corresponding json-schema
# from the matching `.json` fixture file.
# I.e:
#
#  >> SchemaRenderer.new('my_community/bla').json_schema
#     # parse schema from '*/schema/my_community/bla/schema.json.erb'
class SchemaRenderer
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
    @base_path ||= File.join(MR.fixtures_path, 'schemas')
  end

  # Parsed json-schema
  # If you provide a request param, then we transform the rendered schema to
  # have public urls instead of file paths on the refs. This is used to return
  # schemas on the API
  #
  # Params:
  #  - req: [Rack::Request] the http request for this public schema
  # Return: [Hash] the resulting schema
  def json_schema
    JSON.parse(rendered_schema)
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
      # from: "$ref": "fixtures/schemas/json_ld.json.erb"
      %r{\"\$ref\": \"fixtures/schemas/(.*)\.json\.erb\"},
      # to:   "$ref": "http://myurl.com/schemas/json_ld"
      "\"$ref\": \"#{req.base_url}/schemas/\\1\""
    )
  end

  def schema_file_path
    # if we have name='something', then it will try to find the first schema
    # file, on the following paths, that exists:
    #   schemas/something.json
    #   schemas/something/schema.json
    #   schemas/something.json.erb
    #   schemas/something/schema.json.erb
    @schema_file_path ||= [
      "#{base_path}/#{name}.json",
      "#{base_path}/#{name}/schema.json",
      "#{base_path}/#{name}.json.erb",
      "#{base_path}/#{name}/schema.json.erb"
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
    "fixtures/schemas/#{name}.json.erb"
  end

  # List of all available schemas
  #
  # Return: [List[String]] list of schema names
  def self.all_schemas
    Dir['fixtures/schemas/**/*.json.erb']
      .reject { |path| path.split('/').last.start_with?('_') }
      .map    { |path| path.match(%r{fixtures/schemas/(.*).json.erb})[1] }
      .map    { |path| path.gsub(%r{/schema$}, '') }
  end
end
