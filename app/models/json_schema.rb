require 'schema_renderer'

# Json-schema definition for a given Community resource type
# names should be on the format `community/resource`
class JsonSchema < ActiveRecord::Base
  has_paper_trail

  validates :name, :schema, presence: true
  validates :name, uniqueness: true

  def self.for(name)
    find_or_create_by(name: name) do |json_schema|
      json_schema.schema = SchemaRenderer.new(name).json_schema
    end
  end

  # Utility method to update schemas from the file fixture
  def self.update_from_fixture!(name)
    json_schema = find_by!(name: name)
    json_schema.update! schema: SchemaRenderer.new(name).json_schema
  end

  def public_schema(req)
    JSON.parse schema.to_json.gsub(
      # from: "$ref": "fixtures/schemas/json_ld.json.erb"
      %r{\"\$ref\":\s?\"fixtures/schemas/(.*)\.json\.erb\"},
      # to:   "$ref": "http://myurl.com/schemas/json_ld"
      "\"$ref\": \"#{req.base_url}/schemas/\\1\""
    )
  end
end
