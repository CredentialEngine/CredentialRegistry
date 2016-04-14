require 'rsa_decoded_token'

describe RSADecodedToken, type: :model do
  let(:decoded_token) { RSADecodedToken.new(valid_token, public_key) }

  describe '::payload' do
    it 'returns the token payload' do
      expect(decoded_token.payload.name).to eq('The Constitution at Work')
    end
  end

  describe '::decode' do
    it 'raises a JWT::DecodeError when token can not be decoded' do
      expect do
        decoded_token.token = invalid_token
        decoded_token.decode
      end.to raise_exception(JWT::DecodeError)
    end

    it 'raises a JWT::VerificationError when token can not be verified' do
      another_public_key = OpenSSL::PKey::RSA.generate(2048).public_key

      expect do
        decoded_token.public_key = another_public_key
        decoded_token.decode
      end.to raise_exception(JWT::VerificationError)
    end
  end
end
