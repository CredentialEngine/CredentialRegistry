FactoryBot.define do
  factory :indexed_envelope_resource do
    # rubocop:todo FactoryBot/FactoryAssociationWithStrategy
    envelope_resource { create(:envelope_resource, envelope: envelope) }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
    payload { envelope_resource.processed_resource }

    add_attribute('@id') { envelope_resource.processed_resource['@id'] }
    add_attribute('@type') { envelope_resource.processed_resource['@type'] }
    add_attribute('ceterms:ctid') { envelope_resource.resource_id }

    transient do
      envelope do
        create( # rubocop:todo FactoryBot/FactoryAssociationWithStrategy
          :envelope,
          :with_cer_credential,
          envelope_community: envelope_community,
          skip_validation: true
        )
      end

      # rubocop:todo FactoryBot/FactoryAssociationWithStrategy
      envelope_community { create(:envelope_community, :with_random_name) }
      # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
    end
  end
end
