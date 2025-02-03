RSpec.describe EnvelopeCommunity, type: :model do
  describe 'validations' do
    it 'has required name' do
      community = described_class.new
      expect(community.valid?).to be(false)
      expect(community.errors['name'].first).to eq('can\'t be blank')
    end

    it 'has unique name' do
      community = described_class.new name: 'test-community'
      expect(community.save).to be(true)

      community = described_class.new name: 'test-community'
      expect(community.save).to be(false)
      expect(community.errors['name'].first).to eq('has already been taken')
    end

    it 'has only one default' do
      community = described_class.new name: 'test-community', default: true
      expect(community.save).to be(true)

      community = described_class.new name: 'other-community', default: true
      expect(community.save).to be(false)
      expect(community.errors['default'].first).to eq('has already been taken')
    end
  end

  describe '.default' do
    it 'gets the default entry' do
      described_class.create name: 'community_1'
      described_class.create name: 'community_2', default: true
      described_class.create name: 'community_3'

      expect(described_class.default.name).to eq('community_2')
    end
  end

  describe '.host_mapped' do
    [
      ['lr-staging.learningtapestry.com', 'ce_registry'],
      ['not-mapped.example.com', nil]
    ].each do |host, name|
      it { expect(described_class.host_mapped(host)).to eq(name) }
    end
  end

  describe 'config' do
    it '#config provide the community config' do
      community = described_class.new name: 'ce_registry'
      expect(community.config).to be_a(Hash)
    end

    it '#config resource_type configs can be nested on communities' do
      community = described_class.new name: 'ce_registry'
      comm_config = community.config
      type_config = community.config('organization')
      expect(type_config).to be_a(Hash)
      expect(type_config).not_to be_empty
      expect(comm_config['organization']).to eq type_config
    end

    it '#config raise MR::SchemaDoesNotExist for invalid names' do
      expect { described_class.new(name: 'non-valid').config }.to(
        raise_error(MR::SchemaDoesNotExist)
      )
    end
  end

  describe '#id_prefix' do
    [
      ['ce_registry', 'http://credentialengineregistry.org/resources/'],
      ['learning_registry', nil]
    ].each do |ec, prefix|
      describe ec do
        let(:community) { described_class.new name: ec }

        it { expect(community.id_prefix).to eq(prefix) }
      end
    end
  end

  describe '#id_field' do
    [
      ['ce_registry', 'ceterms:ctid'],
      ['learning_registry', nil]
    ].each do |ec, field|
      describe ec do
        let(:community) { described_class.new(name: ec) }

        it { expect(community.id_field).to eq(field) }
      end
    end
  end
end
