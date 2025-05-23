require 'open3'
require 'spec_helper'

RSpec.describe 'app:create_envelope_community' do # rubocop:todo RSpec/DescribeClass
  let(:message) { result[0] }

  after do
    EnvelopeCommunity.delete_all
  end

  context 'no params' do # rubocop:todo RSpec/ContextWording
    let(:error) { result[1] }
    let(:result) { Open3.capture3('bin/rake app:create_envelope_community') }

    it 'returns error' do
      expect { result }.not_to change(EnvelopeCommunity, :count)
      expect(error).to eq("Name can't be blank\n")
    end
  end

  context 'new community' do # rubocop:todo RSpec/ContextWording
    context 'only name' do # rubocop:todo RSpec/ContextWording
      let(:name) { 'FOO-bar' }

      let(:result) do
        Open3.capture3(
          'bin/rake app:create_envelope_community -- ' \
          "--name '#{name}'"
        )
      end

      it 'creates new community' do # rubocop:todo RSpec/MultipleExpectations
        expect { result }.to change(EnvelopeCommunity, :count).by(1)

        community = EnvelopeCommunity.last
        expect(community.default?).to be(false)
        expect(community.name).to eq('foo_bar')
        expect(community.secured?).to be(false)
        expect(community.secured_search?).to be(false)

        expect(message).to eq("Envelope community `foo_bar` created!\n")
      end
    end

    context 'all arguments' do # rubocop:todo RSpec/ContextWording
      let(:name) { ' foo BAR ' }
      let(:result) do
        Open3.capture3(
          'bin/rake app:create_envelope_community -- ' \
          "--name '#{name}' " \
          '--default yes ' \
          '--secured no ' \
          '--secured-search yes'
        )
      end

      it 'creates new community' do # rubocop:todo RSpec/MultipleExpectations
        expect { result }.to change(EnvelopeCommunity, :count).by(1)

        community = EnvelopeCommunity.last
        expect(community.default?).to be(true)
        expect(community.name).to eq('foobar')
        expect(community.secured?).to be(false)
        expect(community.secured_search?).to be(true)

        expect(message).to eq("Envelope community `foobar` created!\n")
      end
    end
  end

  context 'existing community' do # rubocop:todo RSpec/ContextWording
    let(:name) { 'FOO - BAR' }

    let!(:envelope_community) do
      create(
        :envelope_community,
        default: true,
        name: 'foo_bar',
        secured: true,
        secured_search: true
      )
    end

    context 'only name' do # rubocop:todo RSpec/ContextWording
      let(:result) do
        Open3.capture3(
          'bin/rake app:create_envelope_community -- ' \
          "--name '#{name}'"
        )
      end

      it 'does nothing' do
        expect do
          result
          envelope_community.reload
        end.to not_change { EnvelopeCommunity.count }
          .and not_change { envelope_community.default? }
          .and not_change { envelope_community.name }
          .and not_change { envelope_community.secured? }
          .and not_change { envelope_community.secured_search? }

        expect(message).to eq("Envelope community `foo_bar` updated!\n")
      end
    end

    context 'all arguments' do # rubocop:todo RSpec/ContextWording
      let(:result) do
        Open3.capture3(
          'bin/rake app:create_envelope_community -- ' \
          "--name '#{name}' " \
          '--default no ' \
          '--secured no ' \
          '--secured-search no'
        )
      end

      it 'updates existing community' do # rubocop:todo RSpec/ExampleLength
        expect do
          result
          envelope_community.reload
        end.to not_change { EnvelopeCommunity.count }
          .and not_change { envelope_community.name }
          .and change(envelope_community, :default?).to(false)
                                                    .and change(envelope_community,
                                                                :secured?).to(false)
          .and change(
            envelope_community, :secured_search?
          ).to(false)

        expect(message).to eq("Envelope community `foo_bar` updated!\n")
      end
    end
  end
end
