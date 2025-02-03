# rubocop:todo RSpec/MultipleMemoizedHelpers
RSpec.shared_context 'envelopes for search' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
  # rubocop:todo RSpec/IndexedLet
  let(:resource_1) do # rubocop:todo Naming/VariableNumber, RSpec/IndexedLet
    build(
      :resource,
      name: 'Harry Potter and the Philosopher\'s Stone',
      description: 'The plot follows Harry Potter, a young wizard who ' \
                   'discovers his magical heritage as he makes close friends ' \
                   'and a few enemies in his first year at the Hogwarts School ' \
                   'of Witchcraft and Wizardry.'
    )
  end
  # rubocop:enable RSpec/IndexedLet

  # rubocop:todo RSpec/IndexedLet
  let(:resource_2) do # rubocop:todo Naming/VariableNumber, RSpec/IndexedLet
    build(
      :resource,
      name: 'test 1',
      description: 'bla ble bli',
      test: true,
      nested: [{ num: 42 }]
    )
  end
  # rubocop:enable RSpec/IndexedLet

  # rubocop:todo RSpec/IndexedLet
  let(:resource_3) do # rubocop:todo Naming/VariableNumber, RSpec/IndexedLet
    build(
      :resource,
      name: 'test 2',
      description: 'lorem ipsum dolor ...',
      test: true,
      nested: [{ num: 'not-42' }]
    )
  end
  # rubocop:enable RSpec/IndexedLet

  # rubocop:todo RSpec/IndexedLet
  let(:resource_4) do # rubocop:todo Naming/VariableNumber, RSpec/IndexedLet
    build(
      :cer_cred,
      'ceterms:ctid' => 'urn:ctid:a294c050-feac-4926-9af4-0437df063720'
    )
  end
  # rubocop:enable RSpec/IndexedLet

  let!(:envelope1) do # rubocop:todo RSpec/IndexedLet
    create(
      :envelope,
      created_at: Faker::Time.backward(days: 6),
      updated_at: Faker::Time.backward(days: 6)
    )
  end

  let!(:envelope2) do # rubocop:todo RSpec/IndexedLet
    create(
      :envelope,
      created_at: Faker::Time.backward(days: 6),
      resource: jwt_encode(resource_1),
      updated_at: Faker::Time.backward(days: 6)
    )
  end

  let!(:envelope3) do # rubocop:todo RSpec/IndexedLet
    create(
      :envelope,
      created_at: Faker::Time.backward(days: 6),
      resource: jwt_encode(resource_2),
      updated_at: Faker::Time.backward(days: 6)
    )
  end

  let!(:envelope4) do # rubocop:todo RSpec/IndexedLet
    create(
      :envelope,
      created_at: Faker::Time.backward(days: 6),
      resource: jwt_encode(resource_3),
      updated_at: Faker::Time.backward(days: 6)
    )
  end

  let!(:envelope5) do # rubocop:todo RSpec/IndexedLet
    create(
      :envelope,
      :from_cer,
      created_at: Faker::Time.backward(days: 6),
      resource: jwt_encode(resource_4),
      updated_at: Faker::Time.backward(days: 6)
    )
  end

  let!(:envelope6) do # rubocop:todo RSpec/IndexedLet
    create(
      :envelope,
      :from_cer,
      created_at: Faker::Time.backward(days: 6),
      updated_at: Faker::Time.backward(days: 6)
    )
  end

  let!(:envelope7) do # rubocop:todo RSpec/IndexedLet
    create(
      :envelope,
      :paradata,
      created_at: Faker::Time.backward(days: 6),
      updated_at: Faker::Time.backward(days: 6)
    )
  end

  let(:envelopes) do
    [
      envelope1,
      envelope2,
      envelope3,
      envelope4,
      envelope5,
      envelope6,
      envelope7
    ]
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
