require 'erb'

# json-schema renderer
class JSONSchema
  include ERB::Util

  attr_reader :name, :prefix

  def initialize(name, prefix = nil)
    @name = name
    @prefix = prefix
  end

  def rendered
    @rendered ||= ERB.new(template).result(binding)
  end

  def schema
    @schema ||= JSON.parse rendered
  end

  def public_schema(req)
    @public_schema ||= begin
      # change refs to be public uris
      JSON.parse rendered.gsub(
        # from: "$ref": "json_ld.json"
        /\"\$ref\": \"(.*)\.json\"/,
        # to:   "$ref": "http://myurl.com/api/schemas/json_ld"
        "\"$ref\": \"#{req.base_url}/api/schemas/\\1\""
      )
    end
  end

  def file_path
    @file_path ||= File.expand_path("../../schemas/#{name}.json.erb", __FILE__)
  end

  def template
    @template ||= File.read(file_path)
  end

  def exist?
    File.exist?(file_path)
  end

  def partial(name, prefix = nil)
    self.class.new(name, prefix).rendered
  end

  def k(key)
    prefix ? "#{prefix}:#{key}" : key
  end
end
