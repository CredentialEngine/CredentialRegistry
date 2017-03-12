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

  def public_schema(_req)
    # TODO: implement-me
    schema
  end
end
