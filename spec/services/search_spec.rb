require 'services/search'
require_relative '../support/shared_contexts/envelopes_for_search'

RSpec.describe MR::Search, type: :service do # rubocop:todo RSpec/SpecFilePathFormat
  include_context 'envelopes for search'

  it 'filter params on initialize' do
    params = { per_page: 10, page: 2, something: 'bla' }
    search = described_class.new(params)
    expect(search.params.keys).to eq(['something'])
  end

  it 'empty params return a match all query' do
    all_count = Envelope.count
    expect(all_count).to be > 0

    search_count = described_class.new({}).run.count
    expect(search_count).to eq all_count
  end

  it 'extract fts param' do
    expect(described_class.new(fts: 'something').fts).to eq 'something'
  end

  it 'extract community param' do
    expect(described_class.new(envelope_community: 'Comm').community).to eq 'comm'
    expect(described_class.new(community: 'diff-comm').community).to eq 'diff_comm'
    expect(described_class.new(community: '').community).to be_nil
  end

  it 'extract type param' do
    expect(described_class.new(type: 'paradata').type).to eq 'paradata'
  end

  it 'extract resource_type param' do
    expect(
      described_class.new(community: 'ce_registry',
                          resource_type: 'organizations')
                .resource_type
    ).to eq 'organization'
  end

  it 'extract date_range param' do # rubocop:todo RSpec/MultipleExpectations
    range = described_class.new(from: '2016-08-25T00:00:00Z',
                                until: '2016-08-27T23:59:59Z').date_range

    expect(range[:from]).to be_a(Time)
    expect(range[:from]).to eq Chronic.parse('2016-08-25T00:00:00Z')
    expect(range[:until]).to be_a(Time)
    expect(range[:until]).to eq Chronic.parse('2016-08-27T23:59:59Z')
  end

  it 'date_range parse natural language terms' do
    range = described_class.new(from: 'february 1st',
                                until: '3 days ago').date_range

    expect(range[:from]).to be_a(Time)
    expect(range[:until]).to be_a(Time)
    expect([range[:from].day, range[:from].month]).to eq([1, 2])
  end

  it 'date_range is a compact hash' do
    range = described_class.new(from: '', until: '3 days ago').date_range
    expect(range[:from]).to be_nil

    range = described_class.new(from: '', until: nil).date_range
    expect(range).to be_nil
  end

  it 'search by fts partials (name)' do
    res = described_class.new(fts: 'ary otter and philo ston').run
    expect(res.first.processed_resource['name']).to(
      eq('Harry Potter and the Philosopher\'s Stone')
    )
  end

  it 'search by fts full words (desc)' do
    res = described_class.new(fts: 'Hogwarts').run
    expect(res.first.processed_resource['description']).to(
      include('Hogwarts School of Witchcraft and Wizardry')
    )
  end

  it 'search by community' do
    res = described_class.new(envelope_community: 'ce_registry').run
    expect(res.count).to eq 2
    expect(res.first.envelope_community.name).to eq 'ce_registry'
  end

  it 'search by type' do
    res = described_class.new(type: 'paradata').run
    expect(res.map(&:envelope_type).uniq).to eq ['paradata']
  end

  it 'search by resource_type' do
    res = described_class.new(envelope_community: 'ce_registry',
                              resource_type: 'organization').run
    expect(
      res.map { |e| e.processed_resource['@type'] }.uniq
    ).to eq ['ceterms:CredentialOrganization']
  end

  it 'search by date_range' do
    res = described_class.new(from: '1 week ago').run
    expect(res.count).to be > 0
    expect(res.count).to eq Envelope.count

    res = described_class.new(until: '1 week ago').run
    expect(res.count).to eq 0
  end

  it 'search by resource root field' do
    res = described_class.new(community: 'learning_registry', name: 'test 1').run
    expect(res.count).to eq 1

    res = described_class.new(community: 'learning_registry', test: 'true').run
    expect(res.count).to eq 2
    expect(res.first.processed_resource['test']).to be true
  end

  it 'search by resource nested field' do
    res = described_class.new(community: 'learning_registry',
                              nested: [{ num: 42 }].to_json).run
    expect(res.count).to eq 1
    expect(res.first.processed_resource['nested'].first['num']).to eq 42
  end

  it 'search by resource fields usig aliases' do # rubocop:todo RSpec/MultipleExpectations
    # ctid comes from spec/support/shared_contexts/envelopes_for_search.rb
    ctid = 'urn:ctid:a294c050-feac-4926-9af4-0437df063720'

    res = described_class.new(envelope_community: 'ce_registry',
                              'ceterms:ctid' => ctid).run
    expect(res.count).to eq 1
    expect(res.first.processed_resource['ceterms:ctid']).to eq ctid

    res = described_class.new(envelope_community: 'ce_registry', ctid: ctid).run
    expect(res.count).to eq 1
    expect(res.first.processed_resource['ceterms:ctid']).to eq ctid
  end

  it 'uses prepared_queries if they are defined on the config' do
    res = described_class.new(envelope_community: 'learning_registry',
                              publisher_name: 'someone').run

    expect(res.to_sql).to match(
      /processed_resource @> '{ "publisher": { "name": "someone" } }'/
    )
  end

  context 'sorting' do # rubocop:todo RSpec/ContextWording
    let(:envelopes) { [envelope1, envelope2, envelope3, envelope4, envelope7] }
    let(:envelope_resources) { envelopes.map { |env| env.envelope_resources.first } }
    let(:results) do
      described_class.new(
        community: 'learning_registry',
        sort_by: sort_by,
        sort_order: sort_order
      ).run
    end
    let(:sort_by) {} # rubocop:todo Lint/EmptyBlock
    let(:sort_order) {} # rubocop:todo Lint/EmptyBlock

    context 'default' do # rubocop:todo RSpec/ContextWording
      it 'sorts by updated_at DESC' do
        expect(results).to eq(envelope_resources.sort_by(&:updated_at).reverse)
      end
    end

    context 'invalid sort column' do # rubocop:todo RSpec/ContextWording
      let(:sort_by) { Faker::Lorem.word }

      # rubocop:todo RSpec/NestedGroups
      context 'default order' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'sorts by updated_at DESC' do
          expect(results).to eq(envelope_resources.sort_by(&:updated_at).reverse)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'invalid order' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:sort_order) { Faker::Lorem.word }

        it 'sorts by updated_at DESC' do
          expect(results).to eq(envelope_resources.sort_by(&:updated_at).reverse)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'ASC' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:sort_order) { 'asc' }

        it 'sorts by updated_at ASC' do
          expect(results).to eq(envelope_resources.sort_by(&:updated_at))
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'DESC' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:sort_order) { 'desc' }

        it 'sorts by updated_at DESC' do
          expect(results).to eq(envelope_resources.sort_by(&:updated_at).reverse)
        end
      end
    end

    context ':created_at' do # rubocop:todo RSpec/ContextWording
      let(:sort_by) { 'created_at' }

      # rubocop:todo RSpec/NestedGroups
      context 'default order' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'sorts by created_at DESC' do
          expect(results).to eq(envelope_resources.sort_by(&:created_at).reverse)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'invalid order' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:sort_order) { Faker::Lorem.word }

        it 'sorts by created_at DESC' do
          expect(results).to eq(envelope_resources.sort_by(&:created_at).reverse)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'ASC' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:sort_order) { 'asc' }

        it 'sorts by created_at ASC' do
          expect(results).to eq(envelope_resources.sort_by(&:created_at))
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'DESC' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:sort_order) { 'desc' }

        it 'sorts by created_at DESC' do
          expect(results).to eq(envelope_resources.sort_by(&:created_at).reverse)
        end
      end
    end

    context ':updated_at' do # rubocop:todo RSpec/ContextWording
      let(:sort_by) { 'updated_at' }

      # rubocop:todo RSpec/NestedGroups
      context 'default order' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'sorts by updated_at DESC' do
          expect(results).to eq(envelope_resources.sort_by(&:updated_at).reverse)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'invalid order' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:sort_order) { Faker::Lorem.word }

        it 'sorts by updated_at DESC' do
          expect(results).to eq(envelope_resources.sort_by(&:updated_at).reverse)
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'ASC' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:sort_order) { 'asc' }

        it 'sorts by updated_at ASC' do
          expect(results).to eq(envelope_resources.sort_by(&:updated_at))
        end
      end

      # rubocop:todo RSpec/NestedGroups
      context 'DESC' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:sort_order) { 'desc' }

        it 'sorts by updated_at DESC' do
          expect(results).to eq(envelope_resources.sort_by(&:updated_at).reverse)
        end
      end
    end
  end
end
