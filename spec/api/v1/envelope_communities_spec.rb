require_relative 'shared_examples/auth'

RSpec.describe 'Envelope communities API' do # rubocop:todo RSpec/DescribeClass
  before do
    create(:envelope_community, name: 'ce_registry')
  end

  describe 'POST /metadata/organizations' do
    include_examples 'requires auth', :post, '/metadata/envelope_communities'

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'as admin' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers
      let(:admin) { token.admin }
      let(:default) { true }
      let(:name) { Faker::Lorem.characters }
      let(:params) { { default:, name:, secured:, secured_search: } }
      let(:secured) { true }
      let(:secured_search) { true }
      let(:token) { create(:auth_token, :admin) }

      before do
        post '/metadata/envelope_communities',
             params,
             'Authorization' => "Token #{token.value}"
      end

      # rubocop:todo RSpec/NestedGroups
      context 'new community' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'empty name' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:name) { '' }

          it 'returns 422' do
            expect_status(:unprocessable_entity)
            expect_json('error', "Name can't be blank")
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'only name' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          let(:params) { { name: } }

          # rubocop:enable RSpec/NestedGroups
          it 'creates a new community' do # rubocop:todo RSpec/MultipleExpectations
            community = EnvelopeCommunity.order(:created_at).last
            expect(community.default).to be(false)
            expect(community.name).to eq(name)
            expect(community.secured).to be(false)
            expect(community.secured_search).to be(false)
            expect_status(:created)
            expect_json('name', community.name)
            expect_json('default', false)
            expect_json('secured', false)
            expect_json('secured_search', false)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        context 'all params' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          it 'creates a new community' do # rubocop:todo RSpec/MultipleExpectations
            community = EnvelopeCommunity.order(:created_at).last
            expect(community.default).to be(true)
            expect(community.name).to eq(name)
            expect(community.secured).to be(true)
            expect(community.secured_search).to be(true)
            expect_status(:created)
            expect_json('name', community.name)
            expect_json('default', true)
            expect_json('secured', true)
            expect_json('secured_search', true)
          end
        end
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'existing community' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        let(:default) { false }
        let(:name) { community.name }

        let(:community) do
          create(
            :envelope_community,
            default: true,
            secured: false,
            secured_search: false
          )
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'only name' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          let(:params) { { name: } }

          # rubocop:enable RSpec/NestedGroups
          it 'creates a new community' do # rubocop:todo RSpec/MultipleExpectations
            community.reload
            expect(community.default).to be(true)
            expect(community.name).to eq(name)
            expect(community.secured).to be(false)
            expect(community.secured_search).to be(false)
            expect_status(:created)
            expect_json('name', community.name)
            expect_json('default', true)
            expect_json('secured', false)
            expect_json('secured_search', false)
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        context 'all params' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          it 'creates a new community' do # rubocop:todo RSpec/MultipleExpectations
            community.reload
            expect(community.default).to be(false)
            expect(community.name).to eq(name)
            expect(community.secured).to be(true)
            expect(community.secured_search).to be(true)
            expect_status(:created)
            expect_json('name', community.name)
            expect_json('default', false)
            expect_json('secured', true)
            expect_json('secured_search', true)
          end
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    context 'as publisher' do # rubocop:todo RSpec/ContextWording
      let(:token) { create(:auth_token) }

      it 'returns 403' do
        post '/metadata/envelope_communities',
             { name: '' },
             'Authorization' => "Token #{token.value}"

        expect_status(:forbidden)
      end
    end
  end
end
