namespace :app do
  desc 'Creates an envelope community'
  task create_envelope_community: :cer_environment do |_task, args|
    name = nil
    options = {}

    opts = OptionParser.new
    opts.banner = 'Usage: rake app:create_envelope_community [options]'
    opts.on('--name=STRING', String) { name = _1 }
    opts.on('--default=(yes|no)', TrueClass) { options[:default] = _1 }
    opts.on('--secured=(yes|no)', TrueClass) { options[:secured] = _1 }
    opts.on('--secured-search=(yes|no)', TrueClass) { options[:secured_search] = _1 }
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
end
