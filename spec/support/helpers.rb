# General utility methods for tests
module Helpers
  def with_versioning
    was_enabled = PaperTrail.enabled?
    was_enabled_for_controller = PaperTrail.enabled_for_controller?
    PaperTrail.enabled = true
    PaperTrail.enabled_for_controller = true
    begin
      yield
    ensure
      PaperTrail.enabled = was_enabled
      PaperTrail.enabled_for_controller = was_enabled_for_controller
    end
  end

  def jwt_encode(data, signed: true)
    if signed
      JWT.encode data, private_key, 'RS256'
    else
      JWT.encode data, nil, 'none'
    end
  end

  def private_key
    key_path = File.expand_path('../fixtures/private_key.txt', __FILE__)

    OpenSSL::PKey::RSA.new(File.read(key_path))
  end

  def public_key
    private_key.public_key
  end

  def valid_token
    jwt_encode(attributes_for(:resource))
  end

  def invalid_token
    jwt_encode(attributes_for(:resource), signed: false)
  end

  def default_payload
    {
      email: 'me@example.org',
      action: 'approve'
    }
  end
end
