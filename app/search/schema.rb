module Search
  # Search schema builder.
  # Given a schema_name, it builds the schema from a matching `.json` file.
  # I.e:
  #
  #  >> Search::Schema.new('my_community/bla').schema
  #     # finds the '*/schema/my_community/bla/search.json.erb' file and
  #     # parse it to a schema Hash
  #
  class Schema
    attr_reader :name

    # Params:
    #  - name: [String|Symbol] schema name, corresponds to the json file name
    def initialize(name)
      @name = name
    end

    # Parse rendered json
    # Return: [Hash] the resulting schema
    def schema
      @schema ||= JSON.parse content
    end

    # resolve file paths for the corresponding schema name
    # Return: [String]
    def file_path
      @file_path ||= File.expand_path(
        "../../schemas/#{name}/search.json", __FILE__
      )
    end

    # load template from file
    # Return: [String]
    def content
      @content ||= File.read(file_path)
    end

    # Tell if the corresponding template exists
    # Return: [Boolean]
    def exist?
      File.exist? file_path
    end

    # List of all available schemas
    #
    # Return: [List[String]] list of schema names
    def self.all_schemas
      Dir['app/schemas/**/*.json']
        .select { |path| !path.split('/').last.start_with?('_') }
        .map    { |path| path.match(%r{app/schemas/(.*)/search.json})[1] }
    end
  end
end
