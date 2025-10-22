RSpec.describe SyncEnvelopeGraphWithS3 do # rubocop:todo RSpec/MultipleMemoizedHelpers
  let(:envelope) { build(:envelope, :from_cer) }
  let(:s3_bucket) { double('s3_bucket') } # rubocop:todo RSpec/VerifiedDoubles
  let(:s3_bucket_name) { Faker::Lorem.word }
  let(:s3_object) { double('s3_object') } # rubocop:todo RSpec/VerifiedDoubles
  let(:s3_region) { 'aws-s3_region-test' }
  let(:s3_resource) { double('s3_resource') } # rubocop:todo RSpec/VerifiedDoubles
  let(:s3_url) { Faker::Internet.url }

  context 'without bucket' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    describe '.upload' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      it 'does nothing' do
        expect { described_class.upload(envelope) }.not_to raise_error
      end
    end

    describe '.remove' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      it 'does nothing' do
        expect { described_class.remove(envelope) }.not_to raise_error
      end
    end
  end

  context 'with bucket' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    before do
      ENV['AWS_REGION'] = s3_region
      ENV['ENVELOPE_GRAPHS_BUCKET'] = s3_bucket_name

      # rubocop:todo RSpec/MessageSpies
      expect(Aws::S3::Resource).to receive(:new) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
        # rubocop:enable RSpec/MessageSpies
        .with(region: s3_region)
        .and_return(s3_resource)
        .at_least(:once)

      # rubocop:todo RSpec/MessageSpies
      expect(s3_resource).to receive(:bucket) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
        # rubocop:enable RSpec/MessageSpies
        .with(s3_bucket_name)
        .and_return(s3_bucket)
        .at_least(:once)

      # rubocop:todo RSpec/MessageSpies
      expect(s3_bucket).to receive(:object) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
        # rubocop:enable RSpec/MessageSpies
        .with("ce_registry/#{envelope.envelope_ceterms_ctid}.json")
        .and_return(s3_object)
        .at_least(:once)

      # rubocop:todo RSpec/MessageSpies
      expect(s3_object).to receive(:put).with( # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies
        # rubocop:enable RSpec/MessageSpies
        body: envelope.processed_resource.to_json,
        content_type: 'application/json'
      )

      # rubocop:todo RSpec/StubbedMock
      # rubocop:todo RSpec/MessageSpies
      expect(s3_object).to receive(:public_url).and_return(s3_url) # rubocop:todo RSpec/ExpectInHook, RSpec/MessageSpies, RSpec/StubbedMock
      # rubocop:enable RSpec/MessageSpies
      # rubocop:enable RSpec/StubbedMock
    end

    describe '.upload' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      it 'uploads the s3_resource to S3' do
        envelope.save!
        expect(envelope.s3_url).to eq(s3_url)
      end
    end

    describe '.remove' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      it 'uploads the s3_resource to S3' do
        expect(s3_object).to receive(:delete) # rubocop:todo RSpec/MessageSpies
        envelope.save!
        expect { envelope.destroy }.not_to raise_error
      end
    end
  end
end
