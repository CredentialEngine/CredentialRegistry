RSpec.describe ContainerRepository do # rubocop:todo RSpec/MultipleMemoizedHelpers
  subject(:container_repository) { described_class.new(envelope) }

  let(:graph) { envelope.reload.processed_resource.fetch('@graph') }
  let(:existing_subresource) { attributes_for(:cer_collection_member).stringify_keys }
  let(:initial_graph) { [initial_container, existing_subresource] }
  let(:new_subresource) { attributes_for(:cer_collection_member).stringify_keys }
  let(:today) { Date.current + 1.week }

  let(:envelope) do
    create(
      :envelope,
      :from_cer,
      processed_resource: { '@graph' => initial_graph }
    )
  end

  let(:initial_container) do
    attributes_for(
      :cer_collection,
      member_ids: [existing_subresource['@id']]
    ).stringify_keys
  end

  describe '#add_member_uri' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    let(:new_uri) { new_subresource['@id'] }
    let(:existing_uri) { existing_subresource['@id'] }

    let(:updated_container) do
      initial_container.merge('ceterms:hasMember' => [existing_uri, new_uri])
    end

    it 'appends only unique URIs to hasMember' do # rubocop:todo RSpec/ExampleLength
      expect do
        travel_to(today) do
          expect(container_repository.add_member_uri([
            existing_uri,
            new_uri,
            existing_uri,
            new_uri
          ])).to be(true)
        end

        envelope.reload
      end.to change {
        envelope.processed_resource.dig('@graph', 0, 'ceterms:hasMember')
      }.from([existing_uri]).to([existing_uri, new_uri])
                            .and change(envelope, :last_verified_on).to(today)
                                                                    .and enqueue_job(ExtractEnvelopeResourcesJob)
        .with(envelope.id)
    end
  end

  describe '#remove_member_uris' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    let(:existing_uri) { existing_subresource['@id'] }

    it 'removes only matching URIs from hasMember' do # rubocop:todo RSpec/ExampleLength
      expect do
        travel_to(today) do
          expect(container_repository.remove_member_uris([
            existing_uri,
            'http://example.com/non-existent'
          ])).to be(true)
        end

        envelope.reload
      end.to change {
        envelope.processed_resource.dig('@graph', 0, 'ceterms:hasMember')
      }.from([existing_uri]).to([])
                             .and change(envelope, :last_verified_on).to(today)
                                                                     .and enqueue_job(ExtractEnvelopeResourcesJob)
        .with(envelope.id)
    end
  end

end
