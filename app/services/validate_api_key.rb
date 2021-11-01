# Validates an API key by calling a validation endpoint in the related account site
class ValidateApiKey
  def self.call(value, community)
    cache_key = ['api_keys', value, community.name]
    expires_in = ENV.fetch('API_KEY_EXPIRATION_PERIOD', 3_600).to_i

    MR.cache.fetch(cache_key, expires_in: expires_in.seconds) do
      response = RestClient.get(
        ENV.fetch('API_KEY_VALIDATION_ENDPOINT'),
        params: { apikey: value, community: community.name }
      )

      body = JSON(response.body)
      body.fetch('valid', false)
    end
  rescue RestClient::Exception => e
    message = "Validation failed for API key #{value} " \
              "in #{community.name} community: #{e.message}"

    MR.logger.error(message)
    Airbrake.notify(message)
    false
  end
end
