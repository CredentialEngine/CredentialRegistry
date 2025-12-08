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

  describe '#add' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'when the item is new' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      let(:updated_container) do
        initial_container.merge('ceterms:hasMember' => [
                                  existing_subresource['@id'],
                                  new_subresource['@id']
                                ])
      end

      it 'adds the member to the container' do # rubocop:todo RSpec/ExampleLength
        expect do
          travel_to(today) do
            expect(container_repository.add(new_subresource)).to be(true)
          end

          envelope.reload
        end.to change {
          envelope.processed_resource['@graph']
        }.from(initial_graph).to([updated_container, existing_subresource, new_subresource])
                             .and change(envelope, :last_verified_on).to(today)
                                                                     # rubocop:todo Layout/LineLength
                                                                     .and enqueue_job(ExtractEnvelopeResourcesJob)
          # rubocop:enable Layout/LineLength
          .with(envelope.id)
      end
    end

    context 'when the item already exists' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      it 'does nothing' do
        expect do
          travel_to(today) do
            expect(container_repository.add(existing_subresource)).to be(false)
          end

          envelope.reload
        end.to not_change {
          envelope.processed_resource['@graph']
        }
        .and not_change { envelope.last_verified_on }
        .and not_enqueue_job(ExtractEnvelopeResourcesJob)
      end
    end
  end

  describe '#remove' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'when the item exists' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      let(:updated_container) do
        initial_container.merge('ceterms:hasMember' => [])
      end

      it 'removes the member from the container' do # rubocop:todo RSpec/ExampleLength
        expect do
          travel_to(today) do
            expect(container_repository.remove(existing_subresource['@id'])).to be(true)
          end

          envelope.reload
        end.to change {
          envelope.processed_resource['@graph']
        }.from(initial_graph).to([updated_container])
                             .and change(envelope, :last_verified_on).to(today)
                                                                     # rubocop:todo Layout/LineLength
                                                                     .and enqueue_job(ExtractEnvelopeResourcesJob)
          # rubocop:enable Layout/LineLength
          .with(envelope.id)
      end
    end

    context 'when the item does not exist' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      it 'does nothing' do
        expect do
          travel_to(today) do
            expect(container_repository.remove('non-existent-id')).to be(false)
          end

          envelope.reload
        end.to not_change {
          envelope.processed_resource['@graph']
        }
        .and not_change { envelope.last_verified_on }
        .and not_enqueue_job(ExtractEnvelopeResourcesJob)
      end
    end
  end
end
