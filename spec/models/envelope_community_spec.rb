describe EnvelopeCommunity, type: :model do
  describe 'validations' do
    it 'has required name' do
      community = EnvelopeCommunity.new
      expect(community.valid?).to eq(false)
      expect(community.errors['name'].first).to eq('can\'t be blank')
    end

    it 'has unique name' do
      community = EnvelopeCommunity.new name: 'test-community'
      expect(community.save).to eq(true)

      community = EnvelopeCommunity.new name: 'test-community'
      expect(community.save).to eq(false)
      expect(community.errors['name'].first).to eq('has already been taken')
    end

    it 'has only one default' do
      community = EnvelopeCommunity.new name: 'test-community', default: true
      expect(community.save).to eq(true)

      community = EnvelopeCommunity.new name: 'other-community', default: true
      expect(community.save).to eq(false)
      expect(community.errors['default'].first).to eq('has already been taken')
    end
  end

  describe '.default' do
    it 'gets the default entry' do
      EnvelopeCommunity.create name: 'community_1'
      EnvelopeCommunity.create name: 'community_2', default: true
      EnvelopeCommunity.create name: 'community_3'

      expect(EnvelopeCommunity.default.name).to eq('community_2')
    end
  end

  describe 'config' do
    it '#config provide the community config' do
      community = EnvelopeCommunity.new name: 'ce_registry'
      expect(community.config).to be_a_kind_of(Hash)
    end

    it '#config resource_type configs can be nested on communities' do
      community = EnvelopeCommunity.new name: 'ce_registry'
      comm_config = community.config
      type_config = community.config('organization')
      expect(type_config).to be_a_kind_of(Hash)
      expect(type_config).to_not be_empty
      expect(comm_config['organization']).to eq type_config
    end

    it '#config raise MR::SchemaDoesNotExist for invalid names' do
      expect { EnvelopeCommunity.new(name: 'non-valid').config }.to(
        raise_error(MR::SchemaDoesNotExist)
      )
    end
  end
end
