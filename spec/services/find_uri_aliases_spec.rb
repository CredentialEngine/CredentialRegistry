require 'spec_helper'

RSpec.describe FindUriAliases do
  let(:result) { FindUriAliases.call(value) }

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

  context 'shorthand value' do
    context 'no namespace' do
      let(:aliases) { %w[lifecycle:Active] }
      let(:value) { 'lifecycle:Active' }

      it 'returns self' do
        expect(result).to eq(aliases)
      end
    end

    context 'with namespace' do
      context 'no redirect' do
        let(:aliases) { %w[https://credreg.net/qdata/terms/median qdata:median] }
        let(:value) { 'qdata:median' }

        it 'returns aliases' do
          expect(result).to eq(aliases)
        end
      end

      context 'with redirect' do
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

  context 'purl.org value' do
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

  context 'credreg.net value' do
    context 'no redirect' do
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
          'creditUnit:DegreeCredit',
        ]
      end

      it 'returns aliases' do
        expect(result).to eq(aliases)
      end
    end
  end

  context 'another value' do
    let(:aliases) { %w[https://www.techelevator.com] }
    let(:value) { 'https://www.techelevator.com/' }

    it 'returns value itself' do
      expect(result).to eq(aliases)
    end
  end
end
