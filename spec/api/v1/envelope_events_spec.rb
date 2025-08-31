# rubocop:todo RSpec/MultipleMemoizedHelpers
RSpec.describe 'Envelope events API' do # rubocop:todo RSpec/DescribeClass
  let(:ce_registry) { create(:envelope_community, name: 'ce_registry') }
  let(:navy) { create(:envelope_community, name: 'navy') }
  let(:destroyed_at) { envelope1.created_at + 1.week }
  let(:updated_at) { envelope1.created_at + 1.day }

  before do
    PaperTrail.enabled = true
  end

  after do
    PaperTrail.enabled = false
  end

  describe 'GET /envelopes/events' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    # rubocop:todo RSpec/IndexedLet
    let!(:envelope1) { create(:envelope, :from_cer, envelope_community: ce_registry) }
    # rubocop:enable RSpec/IndexedLet
    # rubocop:todo RSpec/IndexedLet
    let!(:envelope2) { create(:envelope, :with_cer_credential, envelope_community: navy) }
    # rubocop:enable RSpec/IndexedLet

    before do
      travel_to updated_at do
        envelope1.update!(envelope_version: '2.0.0')
      end

      travel_to destroyed_at do
        envelope1.destroy
      end
    end

    context 'without filters' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      it 'returns all events' do # rubocop:todo RSpec/ExampleLength
        get "/#{ce_registry.name}/envelopes/events"
        expect_status(:ok)
        expect_json_sizes(3)

        expect_json('0.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('0.event', 'destroy')
        expect_json('0.created_at', destroyed_at.change(usec: 0).as_json)

        expect_json('1.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('1.event', 'update')
        expect_json('1.created_at', updated_at.change(usec: 0).as_json)

        expect_json('2.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('2.event', 'create')
        expect_json('2.created_at', envelope1.created_at.as_json)

        get "/#{navy.name}/envelopes/events"
        expect_status(:ok)
        expect_json_sizes(1)

        expect_json('0.envelope_ceterms_ctid', envelope2.envelope_ceterms_ctid)
        expect_json('0.event', 'create')
        expect_json('0.created_at', envelope2.created_at.as_json)
      end
    end

    context 'with `after`' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      it 'returns events created after the given date' do # rubocop:todo RSpec/ExampleLength
        get "/#{ce_registry.name}/envelopes/events?after=#{updated_at}"
        expect_status(:ok)
        expect_json_sizes(2)

        expect_json('0.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('0.event', 'destroy')
        expect_json('0.created_at', destroyed_at.change(usec: 0).as_json)

        expect_json('1.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('1.event', 'update')
        expect_json('1.created_at', updated_at.change(usec: 0).as_json)

        get "/#{ce_registry.name}/envelopes/events?after=#{destroyed_at}"
        expect_status(:ok)
        expect_json_sizes(1)

        expect_json('0.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('0.event', 'destroy')
        expect_json('0.created_at', destroyed_at.change(usec: 0).as_json)
      end
    end

    context 'with `ctid`' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      let!(:envelope3) { create(:envelope, :from_cer, envelope_community: ce_registry) }

      it 'returns events with the given CTID' do # rubocop:todo RSpec/ExampleLength
        get "/#{ce_registry.name}/envelopes/events?ctid=#{envelope1.envelope_ceterms_ctid}"
        expect_status(:ok)
        expect_json_sizes(3)

        expect_json('0.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('0.event', 'destroy')
        expect_json('0.created_at', destroyed_at.change(usec: 0).as_json)

        expect_json('1.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('1.event', 'update')
        expect_json('1.created_at', updated_at.change(usec: 0).as_json)

        expect_json('2.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('2.event', 'create')
        expect_json('2.created_at', envelope1.created_at.as_json)

        get "/#{ce_registry.name}/envelopes/events?ctid=#{envelope3.envelope_ceterms_ctid}"
        expect_status(:ok)
        expect_json_sizes(1)

        expect_json('0.envelope_ceterms_ctid', envelope3.envelope_ceterms_ctid)
        expect_json('0.event', 'create')
        expect_json('0.created_at', envelope3.created_at.as_json)
      end
    end

    context 'with `event`' do # rubocop:todo RSpec/MultipleMemoizedHelpers
      it 'returns events of the given type' do # rubocop:todo RSpec/ExampleLength
        get "/#{ce_registry.name}/envelopes/events?event=create"
        expect_status(:ok)
        expect_json_sizes(1)

        expect_json('0.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('0.event', 'create')
        expect_json('0.created_at', envelope1.created_at.as_json)

        get "/#{ce_registry.name}/envelopes/events?event=destroy"
        expect_status(:ok)
        expect_json_sizes(1)

        expect_json('0.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('0.event', 'destroy')
        expect_json('0.created_at', destroyed_at.change(usec: 0).as_json)

        get "/#{ce_registry.name}/envelopes/events?event=update"
        expect_status(:ok)
        expect_json_sizes(1)

        expect_json('0.envelope_ceterms_ctid', envelope1.envelope_ceterms_ctid)
        expect_json('0.event', 'update')
        expect_json('0.created_at', updated_at.change(usec: 0).as_json)
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
