RSpec.describe API::V1::Containers do # rubocop:todo RSpec/MultipleMemoizedHelpers
  let(:container_ctid) { container.envelope_ceterms_ctid }
  let(:envelope_ctdl_type) { 'ceterms:Collection' }
  let(:subresource) { Faker::Json.shallow_json }
  let(:user) { create(:user) }
  let(:repository) { instance_double(ContainerRepository) }

  let(:container) do
    create(
      :envelope,
      :with_graph_collection,
      envelope_community:,
      envelope_ctdl_type:
    )
  end

  before do
    allow(ContainerRepository).to receive(:new).with(container).and_return(repository)
  end

  context 'with default community' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    let(:envelope_community) do
      create(:envelope_community, name: 'ce_registry', default: true)
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    describe 'PATCH /containers/:container_ctid/resources' do
      # rubocop:todo RSpec/NestedGroups
      context 'when not authenticated' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'returns 401' do
          patch "/containers/#{container_ctid}/resources", subresource
          expect_status(:unauthorized)
        end
      end

      context 'when envelope is not a container type' do # rubocop:todo RSpec/NestedGroups
        let(:envelope_ctdl_type) { 'ceterms:Credential' }

  it 'returns 404' do # rubocop:todo Layout/IndentationConsistency
    patch "/containers/#{container_ctid}/resources",
          subresource,
          'Authorization' => "Token #{user.auth_token.value}"

    expect_status(:not_found)
  end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      context 'when authenticated and container exists' do # rubocop:todo RSpec/NestedGroups
        let(:parsed_subresource) { JSON.parse(subresource) }

        before do
          allow(repository).to receive(:add).with(parsed_subresource)
        end

        it 'instantiates a repository and calls add with the parsed resource' do
          patch "/containers/#{container_ctid}/resources",
                subresource,
                'Authorization' => "Token #{user.auth_token.value}"

          expect(repository).to have_received(:add).with(parsed_subresource)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    describe 'DELETE /containers/:container_ctid/resources/:resource_ctid' do
      let(:resource_ctid) { Envelope.generate_ctid }

      # rubocop:todo RSpec/NestedGroups
      context 'when not authenticated' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'returns 401' do
          delete "/containers/#{container_ctid}/resources/#{resource_ctid}"
          expect_status(:unauthorized)
        end
      end

      context 'when envelope is not a container type' do # rubocop:todo RSpec/NestedGroups
        let(:envelope_ctdl_type) { 'ceterms:Credential' }

  it 'returns 404' do # rubocop:todo Layout/IndentationConsistency
    delete "/containers/#{container_ctid}/resources/#{resource_ctid}",
           {},
           'Authorization' => "Token #{user.auth_token.value}"

    expect_status(:not_found)
  end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      context 'when authenticated and container exists' do # rubocop:todo RSpec/NestedGroups
        before do
          allow(repository).to receive(:remove).with(resource_ctid)
        end

        it 'instantiates a repository and calls remove with the resource CTID' do
          delete "/containers/#{container_ctid}/resources/#{resource_ctid}",
                 {},
                 'Authorization' => "Token #{user.auth_token.value}"

          expect(repository).to have_received(:remove).with(resource_ctid)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
  end

  context 'with explicit community' do # rubocop:todo RSpec/MultipleMemoizedHelpers
    let(:envelope_community) do
      create(:envelope_community, name: 'navy')
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    describe 'PATCH /:community/containers/:container_ctid/resources' do
      # rubocop:todo RSpec/NestedGroups
      context 'when not authenticated' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'returns 401' do
          patch "/navy/containers/#{container_ctid}/resources", subresource

          expect_status(:unauthorized)
        end
      end

      context 'when envelope is not a container type' do # rubocop:todo RSpec/NestedGroups
        let(:envelope_ctdl_type) { 'ceterms:Credential' }

  it 'returns 404' do # rubocop:todo Layout/IndentationConsistency
    patch "/navy/containers/#{container_ctid}/resources",
          subresource,
          'Authorization' => "Token #{user.auth_token.value}"

    expect_status(:not_found)
  end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      context 'when authenticated and container exists' do # rubocop:todo RSpec/NestedGroups
        let(:parsed_subresource) { JSON.parse(subresource) }

        before do
          allow(repository).to receive(:add).with(parsed_subresource)
        end

        it 'instantiates a repository and calls add with the parsed resource' do
          patch "/navy/containers/#{container_ctid}/resources",
                subresource,
                'Authorization' => "Token #{user.auth_token.value}"

          expect(repository).to have_received(:add).with(parsed_subresource)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    describe 'DELETE /:community/containers/:container_ctid/resources/:resource_ctid' do
      let(:resource_ctid) { Envelope.generate_ctid }

      # rubocop:todo RSpec/NestedGroups
      context 'when not authenticated' do # rubocop:todo RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        it 'returns 401' do
          delete "/navy/containers/#{container_ctid}/resources/#{resource_ctid}"
          expect_status(:unauthorized)
        end
      end

      context 'when envelope is not a container type' do # rubocop:todo RSpec/NestedGroups
        let(:envelope_ctdl_type) { 'ceterms:Credential' }

  it 'returns 404' do # rubocop:todo Layout/IndentationConsistency
    delete "/navy/containers/#{container_ctid}/resources/#{resource_ctid}",
           {},
           'Authorization' => "Token #{user.auth_token.value}"

    expect_status(:not_found)
  end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      context 'when authenticated and container exists' do # rubocop:todo RSpec/NestedGroups
        before do
          allow(repository).to receive(:remove).with(resource_ctid)
        end

        it 'instantiates a repository and calls remove with the resource CTID' do
          delete "/navy/containers/#{container_ctid}/resources/#{resource_ctid}",
                 {},
                 'Authorization' => "Token #{user.auth_token.value}"

          expect(repository).to have_received(:remove).with(resource_ctid)
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
  end
end
