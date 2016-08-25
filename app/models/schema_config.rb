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
  attr_reader :name

  # Params:
  #  - name: [String|Symbol] schema name, corresponds to the json files path
  def initialize(name)
    @name = name
  end

  # Parse rendered json
  # Return: [Hash] the resulting schema
  def config
    @config ||= begin
      file_path = base_path + '/config.json'
      content = File.read(file_path)
      JSON.parse content
    end
  rescue Errno::ENOENT
    raise MR::SchemaDoesNotExist, file_path
  end

  # resolve file paths for the corresponding schema name
  # Return: [String]
  def base_path
    @base_path ||= File.expand_path("../../schemas/#{name}", __FILE__)
  end

  # List of all available configs
  #
  # Return: [List[String]] list of schema names
  def self.all_configs
    Dir['app/schemas/**/*.json']
      .select { |path| !path.split('/').last.start_with?('_') }
      .map    { |path| path.match(%r{app/schemas/(.*)/search.json})[1] }
  end
end
