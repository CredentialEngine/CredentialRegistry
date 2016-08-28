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

  let!(:envelopes) do
    [
      create(:envelope),
      create(:envelope, resource: jwt_encode(resource_1))
    ]
  end
end
