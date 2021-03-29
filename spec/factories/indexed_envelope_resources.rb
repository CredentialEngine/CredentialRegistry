FactoryBot.define do
  factory :indexed_envelope_resource do
    envelope_resource { create(:envelope_resource, envelope: envelope) }
    payload { envelope_resource.processed_resource }

    add_attribute('@id') { envelope_resource.processed_resource['@id'] }
    add_attribute('@type') { envelope_resource.processed_resource['@type'] }
    add_attribute('ceterms:ctid') { envelope_resource.resource_id }

    transient do
      envelope do
        create(
          :envelope,
          :with_cer_credential,
          envelope_community: envelope_community,
          skip_validation: true
        )
      end

      envelope_community { create(:envelope_community, :with_random_name) }
    end
  end
end
