require 'spec_helper'

RSpec.describe FindUriAliases do
  let(:result) { described_class.call(value) }

  before do
    JsonContext.create!(
      context: {
        '@context' => {
          'creditUnit' => 'https://purl.org/ctdl/vocabs/creditUnit/',
          'qdata' => 'https://credreg.net/qdata/terms/'
        }
      },
      url: Faker::Internet.url
    )
  end

  context 'shorthand value' do # rubocop:todo RSpec/ContextWording
    context 'no namespace' do # rubocop:todo RSpec/ContextWording
      let(:aliases) { %w[lifecycle:Active] }
      let(:value) { 'lifecycle:Active' }

      it 'returns self' do
        expect(result).to eq(aliases)
      end
    end

    context 'with namespace' do
      # rubocop:todo RSpec/NestedGroups
      context 'no redirect' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:aliases) { %w[https://credreg.net/qdata/terms/median qdata:median] }
        let(:value) { 'qdata:median' }

        it 'returns aliases' do
          expect(result).to eq(aliases)
        end
      end

      context 'with redirect' do # rubocop:todo RSpec/NestedGroups
        let(:value) { 'creditUnit:DegreeCredit' }

        let(:aliases) do
          [
            'https://purl.org/ctdl/vocabs/creditUnit/DegreeCredit',
            'https://credreg.net/ctdl/vocabs/creditUnit/DegreeCredit',
            'creditUnit:DegreeCredit'
          ]
        end

        it 'returns aliases' do
          expect(result).to eq(aliases)
        end
      end
    end
  end

  context 'purl.org value' do # rubocop:todo RSpec/ContextWording
    let(:value) { 'https://purl.org/ctdl/vocabs/creditUnit/DegreeCredit/' }

    let(:aliases) do
      [
        'https://purl.org/ctdl/vocabs/creditUnit/DegreeCredit',
        'https://credreg.net/ctdl/vocabs/creditUnit/DegreeCredit',
        'creditUnit:DegreeCredit'
      ]
    end

    it 'returns aliases' do
      expect(result).to eq(aliases)
    end
  end

  context 'credreg.net value' do # rubocop:todo RSpec/ContextWording
    context 'no redirect' do # rubocop:todo RSpec/ContextWording
      let(:value) { 'https://credreg.net/qdata/terms/median/' }

      let(:aliases) do
        [
          'https://credreg.net/qdata/terms/median',
          'qdata:median'
        ]
      end

      it 'returns aliases' do
        expect(result).to eq(aliases)
      end
    end

    context 'with redirect' do
      let(:value) { 'https://credreg.net/ctdl/vocabs/creditUnit/DegreeCredit' }

      let(:aliases) do
        [
          'https://purl.org/ctdl/vocabs/creditUnit/DegreeCredit',
          'https://credreg.net/ctdl/vocabs/creditUnit/DegreeCredit',
          'creditUnit:DegreeCredit'
        ]
      end

      it 'returns aliases' do
        expect(result).to eq(aliases)
      end
    end
  end

  context 'another value' do # rubocop:todo RSpec/ContextWording
    let(:aliases) { %w[https://www.techelevator.com] }
    let(:value) { 'https://www.techelevator.com/' }

    it 'returns value itself' do
      expect(result).to eq(aliases)
    end
  end
end
