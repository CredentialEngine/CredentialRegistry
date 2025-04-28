namespace :db do
  namespace :seed do
    desc 'Load samples data'
    task samples: %i[cer learning_registry]

    desc 'Load ce/registry sample data'
    task cer: :cer_environment do
      load_all 'ce_registry/assessment_profile.json'
      load_all 'ce_registry/competency.json'
      load_all 'ce_registry/competency_framework.json'
      load_all 'ce_registry/condition_manifest_schema.json'
      load_all 'ce_registry/cost_manifest_schema.json'
      load_all 'ce_registry/credential.json'
      load_all 'ce_registry/learning_opportunity_profile.json'
      load_all 'ce_registry/organization.json'
    end

    desc 'Load learning_registry sample data'
    task learning_registry: :cer_environment do
      load_all 'learning_registry.json'
      load_all 'paradata.json'
    end

    def load_all(path) # rubocop:todo Rake/MethodDefinitionInTask
      raw_content = File.read MR.root_path.join('db', 'seeds', path)
      data = JSON.parse raw_content

      pbar = ProgressBar.create title: path, total: data.size
      data.each do |resource|
        _, err = EnvelopeBuilder.new(params(resource, path), update_if_exists: true).build
        raise "Invalid seed data for #{path} :: #{err}\n\n#{resource}" if err

        pbar.increment
      end
      pbar.finish
    end

    def params(resource, path) # rubocop:todo Rake/MethodDefinitionInTask
      {
        envelope_type: (path.include?('paradata') ? 'paradata' : 'resource_data'),
        envelope_version: '1.0.0',
        envelope_community: path.split('/').first,
        resource: JWT.encode(resource, private_key, 'RS256'),
        resource_format: 'json',
        resource_encoding: 'jwt',
        resource_public_key: Secrets.public_key
      }
    end

    def private_key # rubocop:todo Rake/MethodDefinitionInTask
      OpenSSL::PKey::RSA.new Secrets.private_key
    end
  end
end
