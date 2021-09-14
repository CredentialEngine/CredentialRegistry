require 'extract_envelope_resources_job'

RSpec.describe PublishEnvelopeJob do
  subject { PublishEnvelopeJob }

  describe '#perform' do
    context 'publishing on behalf' do
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
        create(:organization_publisher, organization: publishing_organization, publisher: user.publisher)
      end

      it 'creates an envelope and marks the request as completed successfully' do
        subject.new.perform(publish_request.id)
        publish_request.reload
        expect(publish_request.succeeded?).to be true
        expect(publish_request.failed?).to be false
        expect(publish_request.envelope).not_to be_nil
        expect(publish_request.error).to be_nil
      end
    end

    context 'not authorized to publish' do
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

      it "doesn't create an envelope and marks the request as failed" do
        subject.new.perform(publish_request.id)
        publish_request.reload
        expect(publish_request.succeeded?).to be false
        expect(publish_request.failed?).to be true
        expect(publish_request.envelope).to be_nil
        expect(publish_request.error[0]).to eq "Publisher is not authorized to publish on behalf of this organization"
      end
    end
  end
end
