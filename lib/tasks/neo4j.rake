namespace :envelopes do
  desc 'Imports documents into Neo4j'
  task :environment do
  end

  desc 'Imports a JSON-LD file from Credential Registry.'
  task :neo4j_import do
    require File.expand_path('../../../config/environment', __FILE__)
    require_relative '../../app/services/neo4j_import'

    Envelope.not_deleted.find_each do |envelope|
      Neo4jImport.new(envelope.decoded_resource).create
    end
  end
end
