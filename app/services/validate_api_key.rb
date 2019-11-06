# Validates an API key by calling a validation endpoint in the related account site
class ValidateApiKey
  def self.call(value)
    expires_in = ENV.fetch('API_KEY_EXPIRATION_PERIOD', 3_600).to_i

    MR.cache.fetch(['api_keys', value], expires_in: expires_in.seconds) do
      url = ENV.fetch('API_KEY_VALIDATION_ENDPOINT')
      response = RestClient.get(url, params: { apikey: value })
      body = JSON(response.body)
      body.fetch('valid', false)
    end
  rescue RestClient::Exception => e
    MR.logger.error "Validation failed for API key #{value}: #{e.message}"
    false
  end
end
