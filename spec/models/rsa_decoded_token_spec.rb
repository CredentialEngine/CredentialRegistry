require 'rsa_decoded_token'

RSpec.describe RSADecodedToken, type: :model do
  let(:decoded_token) { RSADecodedToken.new(valid_token, public_key) }

  describe '::payload' do
    it 'returns the token payload' do
      expect(decoded_token.payload.name).to eq('The Constitution at Work')
    end
  end

  describe '::decode' do
    it 'raises an error when token can not be decoded' do
      expect do
        decoded_token.token = invalid_token
        decoded_token.decode
      end.to raise_exception(MR::JWTVerificationError)
    end

    it 'raises an error when token can not be verified' do
      another_public_key = OpenSSL::PKey::RSA.generate(2048).public_key

      expect do
        decoded_token.public_key = another_public_key
        decoded_token.decode
      end.to raise_exception(MR::JWTVerificationError)
    end
  end
end
