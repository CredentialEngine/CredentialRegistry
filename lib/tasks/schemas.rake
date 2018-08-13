require 'json'
require 'rest-client'

namespace :schemas do
  desc 'Loads application environment'
  task :environment do
    require File.expand_path('../../../config/environment', __FILE__)
  end

  desc 'load fixtures'
  task load: :environment do
    require 'schema_renderer'

    SchemaRenderer.all_schemas.each do |name|
      json_schema = JsonSchema.find_or_initialize_by(name: name)
      json_schema.schema = SchemaRenderer.new(name).json_schema
      json_schema.save
      puts "Loaded JSON Schema for: #{name}"
    end
  end

  task load_contexts: :environment do
    require 'json_context'
    urls = Envelope.select("distinct processed_resource->>'@context' as url").map(&:url)
    urls.each do |url|
      puts "Updating context for #{url}."
      context = JSON.parse(RestClient.get(url).body)
      JsonContext.find_or_initialize_by(url: url).tap do |ctx|
        ctx.context = context
        ctx.save!
        puts 'Updated.'
      end
    end
  end
end
