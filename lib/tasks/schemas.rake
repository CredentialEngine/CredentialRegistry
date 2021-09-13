require 'json'
require 'rest-client'

namespace :schemas do
  desc 'load fixtures'
  task load: :cer_environment do
    require 'schema_renderer'

    SchemaRenderer.all_schemas.each do |name|
      json_schema = JsonSchema.find_or_initialize_by(name: name)
      json_schema.schema = SchemaRenderer.new(name).json_schema
      json_schema.save
      puts "Loaded JSON Schema for: #{name}"
    end
  end
end
