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

  def jwt_encode(data, signed: true, key: private_key)
    if signed
      JWT.encode data, OpenSSL::PKey::RSA.new(key), 'RS256'
    else
      JWT.encode data, nil, 'none'
    end
  end

  def private_key
    OpenSSL::PKey::RSA.new(MR.test_keys.private)
  end

  def public_key
    MR.test_keys.public
  end

  def valid_token
    jwt_encode(attributes_for(:resource))
  end

  def invalid_token
    jwt_encode(attributes_for(:resource), signed: false)
  end

  #
  # Takes a regular envelope object and creates a couple of versions on it
  #
  def with_versioned_envelope(envelope)
    with_versioning do
      envelope.update_attributes!(envelope_version: '2')
      envelope.update_attributes!(envelope_version: '3')

      yield if block_given?
    end
  end

  #
  # Reads a dump file and returns an array of transactions that correspond to
  # the parsed JSON envelopes
  #
  def extract_dump_transactions(dump_file)
    transactions = []
    Zlib::GzipReader.open(dump_file).each_line do |line|
      transactions << JSON.parse(Base64.urlsafe_decode64(line.strip))
    end
    transactions
  end

  #
  # Basic matchers to verify that a string is valid Base64
  #
  def expect_base64(string)
    expect(string).to match(%r([A-Za-z0-9+/]+={0,3}))
    expect(string.length % 4).to eq(0)
  end

  def json_resp
    JSON.parse(response.body)
  end
end
