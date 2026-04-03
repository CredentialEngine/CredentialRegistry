namespace :app do
  desc 'Creates an envelope community'
  task create_envelope_community: :cer_environment do |_task, args|
    name = nil
    options = {}

    opts = OptionParser.new
    opts.banner = 'Usage: rake app:create_envelope_community [options]'
    opts.on('--name=STRING', String) { name = it }
    opts.on('--default=(yes|no)', TrueClass) { options[:default] = it }
    opts.on('--secured=(yes|no)', TrueClass) { options[:secured] = it }
    opts.on('--secured-search=(yes|no)', TrueClass) { options[:secured_search] = it }
    # rubocop:todo Lint/ShadowedArgument
    args = opts.order!(ARGV) {} # rubocop:todo Lint/EmptyBlock, Lint/ShadowedArgument
    # rubocop:enable Lint/ShadowedArgument
    opts.parse!(args)

    if name.blank?
      warn("Name can't be blank")
      exit(false)
    end

    community = EnvelopeCommunity.find_or_initialize_by(
      name: EnvelopeCommunity.new(name:).name
    )

    new_record = community.new_record?
    community.update!(options)
    puts "Envelope community `#{community.name}` #{new_record ? 'created' : 'updated'}!"
    exit
  end

  desc 'Generates an auth token'
  task generate_auth_token: :cer_environment do
    missing_vars = %w[ADMIN_NAME PUBLISHER_NAME USER_EMAIL].select do |key|
      ENV[key].blank?
    end

    if missing_vars.any?
      warn("Missing or empty variables: #{missing_vars.join(', ')}")
      exit(false)
    end

    admin = Admin.find_or_create_by!(name: ENV.fetch('ADMIN_NAME'))

    publisher = admin
                .publishers
                .create_with(super_publisher: true)
                .find_or_create_by!(name: ENV.fetch('PUBLISHER_NAME'))

    user = User.find_or_initialize_by(
      admin:,
      email: ENV.fetch('USER_EMAIL'),
      publisher:
    )

    user.new_record? ? user.save! : nil # user.create_auth_token!
    puts user.auth_tokens.last.value
  end

  desc 'Marks current registry changeset state as the initial sync point'
  task mark_changeset_baseline: :cer_environment do
    now = Time.current
    count = 0

    EnvelopeCommunity.find_each do |community|
      latest_version_id = EnvelopeVersion
                          .where(item_type: 'Envelope', envelope_community_id: community.id)
                          .where.not(envelope_ceterms_ctid: nil)
                          .maximum(:id)
      latest_resource_event_id = EnvelopeResourceSyncEvent
                                 .where(envelope_community: community)
                                 .maximum(:id)

      next unless latest_version_id || latest_resource_event_id

      sync = RegistryChangesetSync.find_or_initialize_by(envelope_community: community)
      sync.update!(
        last_activity_at: now,
        last_activity_version_id: latest_version_id,
        last_synced_version_id: latest_version_id,
        last_activity_resource_event_id: latest_resource_event_id,
        last_synced_resource_event_id: latest_resource_event_id,
        scheduled_for_at: nil,
        syncing: false,
        syncing_started_at: nil,
        last_sync_finished_at: now,
        last_sync_error: nil,
        argo_workflows: []
      )

      count += 1
      puts "#{community.name}: version=#{latest_version_id || 'none'} resource_event=#{latest_resource_event_id || 'none'}"
    end

    puts "Marked #{count} registry changeset sync baseline#{'s' unless count == 1}."
  end
end
