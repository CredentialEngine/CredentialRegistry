require 'open3'
require 'spec_helper'

RSpec.describe 'app:create_envelope_community' do # rubocop:todo RSpec/DescribeClass
  let(:error) { result[1] }
  let(:name) { Faker::Lorem.word }

  let(:result) do
    Open3.capture3(
      'bin/rake app:create_envelope_community -- ' \
      "--name #{name}"
    )
  end

  context 'no params' do # rubocop:todo RSpec/ContextWording
    let(:result) { Open3.capture3('bin/rake app:create_envelope_community') }

    it 'returns error' do
      expect { result }.not_to change(EnvelopeCommunity, :count)
      expect(error).to eq("Name can't be blank\n")
    end
  end

  context 'new community' do # rubocop:todo RSpec/ContextWording
    context 'only name' do # rubocop:todo RSpec/ContextWording
      let(:result) do
        Open3.capture3(
          'bin/rake app:create_envelope_community -- ' \
          "--name #{name}"
        )
      end

      it 'creates new community' do # rubocop:todo RSpec/MultipleExpectations
        expect { result }.to change(EnvelopeCommunity, :count).by(1)

        community = EnvelopeCommunity.last
        expect(community.default?).to be(false)
        expect(community.name).to eq(name)
        expect(community.secured?).to be(false)
        expect(community.secured_search?).to be(false)
      end
    end

    context 'all arguments' do # rubocop:todo RSpec/ContextWording
      let(:result) do
        Open3.capture3(
          'bin/rake app:create_envelope_community -- ' \
          "--name #{name} " \
          '--default yes ' \
          '--secured no ' \
          '--secured-search yes'
        )
      end

      it 'creates new community' do # rubocop:todo RSpec/MultipleExpectations
        expect { result }.to change(EnvelopeCommunity, :count).by(1)

        community = EnvelopeCommunity.last
        expect(community.default?).to be(true)
        expect(community.name).to eq(name)
        expect(community.secured?).to be(false)
        expect(community.secured_search?).to be(true)
      end
    end
  end

  context 'existing community', :broken do # rubocop:todo RSpec/ContextWording
    let!(:envelope_community) do
      create(
        :envelope_community,
        default: true,
        name:,
        secured: true,
        secured_search: true
      )
    end

    context 'only name' do # rubocop:todo RSpec/ContextWording
      let(:result) do
        Open3.capture3(
          'bin/rake app:create_envelope_community -- ' \
          "--name #{name}"
        )
      end

      it 'does nothing' do
        expect do
          result
          envelope_community.reload
        end.to not_change { EnvelopeCommunity.count }
          .and not_change { envelope_community.default? }
          .and not_change { envelope_community.secured? }
          .and not_change { envelope_community.secured_search? }
      end
    end

    context 'all arguments' do # rubocop:todo RSpec/ContextWording
      let(:result) do
        Open3.capture3(
          'bin/rake app:create_envelope_community -- ' \
          "--name #{name} " \
          '--default no ' \
          '--secured no ' \
          '--secured-search no'
        )
      end

      it 'creates new community' do
        expect do
          result
          envelope_community.reload
        end.to not_change { EnvelopeCommunity.count }
          .and change(envelope_community, :default?).to(false)
                                                    .and change(envelope_community,
                                                                :secured?).to(false)
          .and change(
            envelope_community, :secured_search?
          ).to(false)
      end
    end
  end
end
