namespace :app do
  desc 'Generates an auth token'
  task generate_auth_token: :cer_environment do
    missing_vars = %w[ADMIN_NAME PUBLISHER_NAME USER_EMAIL].select do |key|
      ENV[key].blank?
    end

    if missing_vars.any?
      STDERR.puts("Missing or empty variables: #{missing_vars.join(', ')}")
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
