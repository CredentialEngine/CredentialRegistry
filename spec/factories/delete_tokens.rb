FactoryBot.define do
  factory :delete_token do
    delete_token { jwt_encode(delete: true) }
    delete_token_format :json
    delete_token_encoding :jwt
    delete_token_public_key do
      File.read('spec/support/fixtures/public_key.txt')
    end

    trait :with_malformed_key do
      delete_token_public_key '----- MALFORMED PUBLIC KEY -----'
    end

    trait :with_different_key do
      delete_token_public_key do
        OpenSSL::PKey::RSA.generate(2048).public_key.to_s
      end
    end
  end
end
