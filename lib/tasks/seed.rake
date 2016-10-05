namespace :db do
  namespace :seed do
    def load_all(path)
      data = fixture_data(path)
      pbar = ProgressBar.create title: path, total: data.size

      data.each do |resource|
        EnvelopeBuilder.new(
          params(resource, path),
          update_if_exists: true
        ).build
        pbar.increment
      end
      pbar.finish
    end

    def fixture_data(path)
      dir = File.expand_path('../../../db/seeds/', __FILE__)
      content = File.read File.join(dir, path)
      JSON.parse content
    end

    def params(resource, path)
      envlp_type = path.include?('paradata') ? 'paradata' : 'resource_data'
      {
        envelope_type: envlp_type,
        envelope_version: '1.0.0',
        envelope_community: path.split('/').first,
        resource: JWT.encode(resource, private_key, 'RS256'),
        resource_format: 'json',
        resource_encoding: 'jwt',
        resource_public_key: public_key
      }
    end

    def private_key
      OpenSSL::PKey::RSA.new get_fixture_key(:private)
    end

    def public_key
      get_fixture_key(:public)
    end

    def get_fixture_key(type)
      dir = File.expand_path('../../../spec/support/fixtures/', __FILE__)
      File.read File.join(dir, "#{type}_key.txt")
    end

    def load_ce_registry
      load_all 'ce_registry/organizations.json'
      load_all 'ce_registry/credentials.json'
    end

    def load_learning_registry
      load_all 'learning_registry/resources.json'
      load_all 'learning_registry/paradata.json'
    end

    desc 'Load samples data'
    task samples: [:environment] do
      load_ce_registry
      load_learning_registry
    end

    desc 'Load cred-reg samples data'
    task cr_samples: [:environment] do
      load_ce_registry
    end
  end
end
