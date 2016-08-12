require 'erb'

# Json-schema builder.
# Given a schema_name, it builds the schema from a matching `.json.erb` file.
# I.e:
#
#  >> JSONSchema.new('my_community/bla').schema
#     # finds the '*/schema/my_community/bla.json.erb' file, render and
#     # parse it to a schema Hash
#
class JSONSchema
  include ERB::Util

  attr_reader :name, :prefix

  # Params:
  #  - name: [String|Symbol] schema name, corresponds to the erb file name
  #  - prefix: [Symbol] used for rendering embeded partial, determine the
  #                     context namespace (if any) for the properties.
  #                     i.e: prefix: :bla => "<%=prop 'name'" => "bla:name"
  def initialize(name, prefix = nil)
    @name = name
    @prefix = prefix
  end

  # Return: [String] Rendered ERB template
  def rendered
    @rendered ||= ERB.new(template).result(binding)
  end

  # Parse rendered json
  # Return: [Hash] the resulting schema
  def schema
    @schema ||= JSON.parse rendered
  end

  # Transform the rendered schema to have public urls instead file paths on refs
  # Used to return schemas on the API
  #
  # Params:
  #  - req: [Rack::Request] the http request for this public schema
  #
  # Return: [Hash] the resulting public schema
  def public_schema(req)
    @public_schema ||= begin
      # change refs to be public uris
      JSON.parse rendered.gsub(
        # from: "$ref": "app/schemas/json_ld.json.erb"
        %r{\"\$ref\": \"app/schemas/(.*)\.json\.erb\"},
        # to:   "$ref": "http://myurl.com/api/schemas/json_ld"
        "\"$ref\": \"#{req.base_url}/api/schemas/\\1\""
      )
    end
  end

  # resolve file paths for the corresponding schema name
  # Return: [String]
  def file_path
    @file_path ||= begin
      possible_paths = [
        "../../schemas/#{name}.json.erb",
        "../../schemas/#{name}/schema.json.erb"
      ].map { |path| File.expand_path(path, __FILE__) }
      possible_paths.select { |path| File.exist?(path) }.first
    end
  end

  # load template from file
  # Return: [String]
  def template
    @template ||= File.read(file_path)
  end

  # Tell if the corresponding template exists
  # Return: [Boolean]
  def exist?
    file_path.present?
  end

  # Render a embeded/partial JSONSchema definition
  # Return: [String] rendered 'partial'
  def partial(name, prefix = nil)
    self.class.new(name, prefix).rendered
  end

  # Helper for properties names that might be namespaced.
  # I.e:
  #   "<%=prop 'something' %>", where prefix='abc' => "abc:something"
  #
  def prop(key)
    prefix ? "#{prefix}:#{key}" : key
  end

  # Refs with proper relative path, used for internal schema validation
  # the public_schema parse this to a public url
  def ref(name)
    "app/schemas/#{name}.json.erb"
  end

  # List of all available schemas
  #
  # Return: [List[String]] list of schema names
  def self.all_schemas
    Dir['app/schemas/**/*.json.erb']
      .select { |path| !path.split('/').last.start_with?('_') }
      .map    { |path| path.match(%r{app/schemas/(.*).json.erb})[1] }
  end
end
