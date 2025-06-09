require 'extract_envelope_resources_job'

RSpec.describe PublishEnvelopeJob do
  subject { described_class }

  describe '#perform' do
    context 'publishing on behalf' do # rubocop:todo RSpec/ContextWording
      let(:envelope_community) { create(:envelope_community) }
      let(:organization) { create(:organization) }
      let(:publishing_organization) { create(:organization) }
      let(:user) { create(:user) }
      let(:publish_request) do
        create(
          :publish_request,
          envelope_community: envelope_community,
          organization: organization,
          publishing_organization: publishing_organization,
          user: user
        )
      end

      before do
        create(:organization_publisher, organization: organization, publisher: user.publisher)
        create(:organization_publisher, organization: publishing_organization,
                                        publisher: user.publisher)
      end

      # rubocop:todo RSpec/MultipleExpectations
      it 'creates an envelope and marks the request as completed successfully' do
        # rubocop:enable RSpec/MultipleExpectations
        subject.new.perform(publish_request.id) # rubocop:todo RSpec/NamedSubject
        publish_request.reload
        expect(publish_request.succeeded?).to be true
        expect(publish_request.failed?).to be false
        expect(publish_request.envelope).not_to be_nil
        expect(publish_request.error).to be_nil
      end
    end

    context 'not authorized to publish' do # rubocop:todo RSpec/ContextWording
      let(:envelope_community) { create(:envelope_community) }
      let(:organization) { create(:organization) }
      let(:publishing_organization) { create(:organization) }
      let(:user) { create(:user) }
      let(:publish_request) do
        create(
          :publish_request,
          envelope_community: envelope_community,
          organization: organization,
          publishing_organization: publishing_organization,
          user: user
        )
      end

      # rubocop:todo RSpec/MultipleExpectations
      it "doesn't create an envelope and marks the request as failed", :broken do
        # rubocop:enable RSpec/MultipleExpectations
        subject.new.perform(publish_request.id) # rubocop:todo RSpec/NamedSubject
        publish_request.reload
        expect(publish_request.succeeded?).to be false
        expect(publish_request.failed?).to be true
        expect(publish_request.envelope).to be_nil
        # rubocop:todo Layout/LineLength
        expect(publish_request.error[0]).to eq 'Publisher is not authorized to publish on behalf of this organization'
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
