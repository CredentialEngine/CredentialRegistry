RSpec.shared_context 'envelopes for search' do
  let(:resource_1) do
    build(
      :resource,
      name: 'Harry Potter and the Philosopher\'s Stone',
      description: 'The plot follows Harry Potter, a young wizard who '\
                 'discovers his magical heritage as he makes close friends '\
                 'and a few enemies in his first year at the Hogwarts School'\
                 ' of Witchcraft and Wizardry.'
    )
  end

  let(:resource_2) do
    build(
      :resource,
      name: 'test 1',
      description: 'bla ble bli',
      test: true,
      nested: [{ num: 42 }]
    )
  end

  let(:resource_3) do
    build(
      :resource,
      name: 'test 2',
      description: 'lorem ipsum dolor ...',
      test: true,
      nested: [{ num: 'not-42' }]
    )
  end

  let(:resource_4) do
    build(
      :cer_cred,
      'ceterms:ctid' => 'urn:ctid:a294c050-feac-4926-9af4-0437df063720'
    )
  end

  let!(:envelopes) do
    [
      create(:envelope),
      create(:envelope, resource: jwt_encode(resource_1)),
      create(:envelope, resource: jwt_encode(resource_2)),
      create(:envelope, resource: jwt_encode(resource_3)),
      create(:envelope, :from_cer, resource: jwt_encode(resource_4)),
      create(:envelope, :from_cer),
      create(:envelope, :paradata)
    ]
  end
end
