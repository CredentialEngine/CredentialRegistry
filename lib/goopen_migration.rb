# module for GoOpen LRv1 -> v2 migration
module GoOpenMigration
  # migration table (populated via Talend job)
  class GoOpenV1Staging < ActiveRecord::Base
    establish_connection :goopen_migration
    self.table_name = 'go_open_v1_staging'
  end

  def self.migrate
    retries ||= 5
    migrate_validated_entries
  rescue ActiveRecord::StatementInvalid, PG::UnableToSend => e
    puts "Failed connection: retries=#{retries}"
    if (retries -= 1).positive?
      GoOpenV1Staging.establish_connection :goopen_migration
      retry
    else
      puts 'Failed migration!', e
    end
  end

  def self.migrate_validated_entries
    qset = GoOpenV1Staging.where(load_status: 'VALIDATED')

    qset.find_in_batches(batch_size: 500) do |group|
      group.each do |item|
        resource = JSON.parse(item.transformed_json)
        _envlp, errors = EnvelopeBuilder.new(envelope_params(resource)).build
        update_status(item) if errors.blank? && !development?
      end
      print '#'
    end
  end

  def self.update_status(item)
    item.update load_status: 'COMPLETE'
  end

  def self.envelope_params(resource)
    {
      envelope_type: 'resource_data',
      envelope_version: '1.0.0',
      envelope_community: 'learning_registry',
      resource: JWT.encode(resource, private_key, 'RS256'),
      resource_format: 'json',
      resource_encoding: 'jwt',
      resource_public_key: MR.test_keys.public
    }
  end

  def self.private_key
    OpenSSL::PKey::RSA.new MR.test_keys.private
  end

  def self.development?
    ENV['RACK_ENV'] == 'development'
  end
end
