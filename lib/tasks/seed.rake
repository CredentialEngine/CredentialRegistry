namespace :db do
  namespace :seed do
    def load_all(path)
      data = fixture_data(path)
      title = path.split('/').last.match(/(.*).json/)[1].titleize
      pbar = ProgressBar.create title: title, total: data.size

      data.each do |resource|
        EnvelopeBuilder.new(params(resource), update_if_exists: true).build
        pbar.increment
      end
      pbar.finish
    end

    def fixture_data(path)
      dir = File.expand_path('../../../db/seeds/', __FILE__)
      content = File.read File.join(dir, path)
      JSON.parse content
    end

    def params(resource)
      {
        envelope_type: 'resource_data',
        envelope_version: '1.0.0',
        envelope_community: 'credential_registry',
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

    desc 'Load credential registry sample data'
    task credential_registry: [:environment] do
      load_all 'credential_registry/organizations.json'
      load_all 'credential_registry/credentials.json'
    end
  end
end
