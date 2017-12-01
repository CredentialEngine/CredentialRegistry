FactoryBot.define do
  factory :registry_metadata do
    digital_signature { { key_location: ['http://example.org/pubkey'] } }
    terms_of_service do
      { submission_tos: 'http://example.org/tos' }
    end
    identity do
      {
        submitter: 'john doe <john@example.org>',
        signer: 'Alpha Node <administrator@example.org>',
        submitter_type: 'user'
      }
    end
    payload_placement 'inline'
    initialize_with { new(attributes) }
  end
end
