require 'index_envelope_job'
require 'precalculate_description_sets_job'

RSpec.describe IndexEnvelopeJob do
  describe '#perform' do
    let(:envelope) { create(:envelope) }
    let(:resource) { envelope.envelope_resources.last }

    before do
      allow(Parallel).to receive(:each).and_yield(resource.id)
    end

    context 'no envelope' do # rubocop:todo RSpec/ContextWording
      before do
        # rubocop:todo RSpec/MessageSpies
        expect(IndexEnvelopeResource).not_to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
        # rubocop:enable RSpec/MessageSpies
        # rubocop:todo RSpec/MessageSpies
        # rubocop:todo RSpec/ExpectInHook
        expect(PrecalculateDescriptionSetsJob).not_to receive(:perform_later)
        # rubocop:enable RSpec/ExpectInHook
        # rubocop:enable RSpec/MessageSpies
      end

      it 'does nothing' do
        described_class.new.perform(0)
      end
    end

    context 'with envelope' do
      before do
        # rubocop:todo RSpec/MessageSpies
        # rubocop:todo RSpec/ExpectInHook
        expect(PrecalculateDescriptionSetsJob).to receive(:perform_later)
          # rubocop:enable RSpec/ExpectInHook
          # rubocop:enable RSpec/MessageSpies
          .with(envelope.id)
      end

      # rubocop:todo RSpec/NestedGroups
      context 'duplicate' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:error) { ActiveRecord::RecordNotUnique.new }

        before do
          # rubocop:todo RSpec/MessageSpies
          expect(Airbrake).to receive(:notify) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
            # rubocop:enable RSpec/MessageSpies
            .with(error, resource_id: resource.resource_id)

          # rubocop:todo RSpec/StubbedMock
          # rubocop:todo RSpec/MessageSpies
          expect(IndexEnvelopeResource).to receive(:call) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
            # rubocop:enable RSpec/MessageSpies
            # rubocop:enable RSpec/StubbedMock
            .with(resource)
            .and_raise(error)
        end

        it 'logs error' do
          described_class.new.perform(envelope.id)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'all good' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        before do
          # rubocop:todo RSpec/MessageSpies
          expect(Airbrake).not_to receive(:notify) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
          # rubocop:enable RSpec/MessageSpies
          # rubocop:todo RSpec/MessageSpies
          # rubocop:todo RSpec/ExpectInHook
          expect(IndexEnvelopeResource).to receive(:call).with(resource)
          # rubocop:enable RSpec/ExpectInHook
          # rubocop:enable RSpec/MessageSpies
        end

        it 'indexes resources and pre-calculates description sets' do
          described_class.new.perform(envelope.id)
        end
      end
    end
  end
end
