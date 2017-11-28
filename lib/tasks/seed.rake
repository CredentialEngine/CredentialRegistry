namespace :db do
  namespace :seed do
    desc 'Load samples data'
    task samples: %i[cer learning_registry]

    desc 'Load ce/registry sample data'
    task cer: :environment do
      load_all 'ce_registry/organizations.json'
      load_all 'ce_registry/credentials.json'
      load_all 'ce_registry/competencies.json'
      load_all 'ce_registry/competency_frameworks.json'
    end

    desc 'Load learning_registry sample data'
    task learning_registry: :environment do
      load_all 'learning_registry/resources.json'
      load_all 'learning_registry/paradata.json'
    end

    def load_all(path)
      raw_content = File.read MR.root_path.join('db', 'seeds', path)
      data = JSON.parse raw_content

      pbar = ProgressBar.create title: path, total: data.size
      data.each do |resource|
        EnvelopeBuilder.new(params(resource, path), update_if_exists: true).build
        pbar.increment
      end
      pbar.finish
    end

    def params(resource, path)
      {
        envelope_type: (path.include?('paradata') ? 'paradata' : 'resource_data'),
        envelope_version: '1.0.0',
        envelope_community: path.split('/').first,
        resource: JWT.encode(resource, private_key, 'RS256'),
        resource_format: 'json',
        resource_encoding: 'jwt',
        resource_public_key: public_key
      }
    end

    def private_key
      OpenSSL::PKey::RSA.new fixture_key(:private)
    end

    def public_key
      fixture_key(:public)
    end

    def fixture_key(type)
      File.read MR.root_path.join('spec', 'support', 'fixtures', "#{type}_key.txt")
    end
  end
end
