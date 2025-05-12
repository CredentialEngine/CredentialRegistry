require_relative 'shared_examples/auth'

RSpec.describe 'Json contexts API' do # rubocop:todo RSpec/DescribeClass
  let(:admin) { token.admin }
  let(:admin_token) { create(:auth_token, :admin) }
  let(:url) { Faker::Internet.url }

  describe 'GET /metadata/json_contexts' do
    let!(:json_context1) { create(:json_context) } # rubocop:todo RSpec/IndexedLet
    let!(:json_context2) { create(:json_context) } # rubocop:todo RSpec/IndexedLet

    include_examples 'requires auth', :post, '/metadata/json_contexts'

    it 'returns all JSON contexts' do
      get '/metadata/json_contexts', 'Authorization' => "Token #{admin_token.value}"
      expect_status(:ok)
      expect_json('0.context', **json_context2.context.symbolize_keys)
      expect_json('0.url', json_context2.url)
      expect_json('1.context', **json_context1.context.symbolize_keys)
      expect_json('1.url', json_context1.url)
    end
  end

  describe 'GET /metadata/json_contexts/:url' do
    let!(:json_context) { create(:json_context) }

    include_examples 'requires auth', :post, '/metadata/json_contexts/0'

    it 'returns the JSON context with the given URL' do
      get "/metadata/json_contexts/#{CGI.escape(json_context.url)}",
          'Authorization' => "Token #{admin_token.value}"
      expect_status(:ok)
      expect_json('context', **json_context.context.symbolize_keys)
      expect_json('url', json_context.url)
    end
  end

  describe 'POST /metadata/json_contexts' do
    let(:context) { JSON(Faker::Json.shallow_json) }
    let(:params) { { context:, url: } }

    include_examples 'requires auth', :post, '/metadata/json_contexts'

    context 'as admin' do # rubocop:todo RSpec/ContextWording
      before do
        post '/metadata/json_contexts',
             params,
             'Authorization' => "Token #{admin_token.value}"
      end

      # rubocop:todo RSpec/NestedGroups
      context 'new context' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
        # rubocop:enable RSpec/NestedGroups
        # rubocop:todo RSpec/NestedGroups
        context 'empty context' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
          # rubocop:enable RSpec/NestedGroups
          let(:context) { nil }

          it 'returns 422' do
            expect_status(:unprocessable_entity)
            expect_json('error', "Context can't be blank")
          end
        end

        # rubocop:todo RSpec/NestedGroups
        context 'empty URL' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
          let(:url) { nil }

          # rubocop:enable RSpec/NestedGroups
          it 'return 422' do
            expect_status(:unprocessable_entity)
            expect_json('error', "Url can't be blank")
          end
        end

        context 'all params' do # rubocop:todo RSpec/ContextWording, RSpec/NestedGroups
          it 'creates a next context' do
            json_context = JsonContext.order(:created_at).last
            expect(json_context.context).to eq(context)
            expect(json_context.url).to eq(url)
            expect_status(:created)
            expect_json('context', **context.symbolize_keys)
            expect_json('url', url)
          end
        end
      end

      # rubocop:todo RSpec/MultipleMemoizedHelpers
      # rubocop:todo RSpec/NestedGroups
      context 'existing context' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
        let(:json_context) { create(:json_context) }
        let(:url) { json_context.url }

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        # rubocop:todo RSpec/NestedGroups
        context 'empty context' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          let(:context) { nil }

          # rubocop:enable RSpec/NestedGroups
          it 'returns 422' do
            expect_status(:unprocessable_entity)
            expect_json('error', "Context can't be blank")
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers

        context 'all params' do # rubocop:todo RSpec/ContextWording, RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
          it 'updates the context' do
            json_context.reload
            expect(json_context.context).to eq(context)
            expect(json_context.url).to eq(url)
            expect_status(:ok)
            expect_json('context', **context.symbolize_keys)
            expect_json('url', url)
          end
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end

    # rubocop:todo RSpec/MultipleMemoizedHelpers
    context 'as publisher' do # rubocop:todo RSpec/ContextWording
      let(:token) { create(:auth_token) }

      it 'returns 403' do
        post '/metadata/json_contexts',
             params,
             'Authorization' => "Token #{token.value}"
        expect_status(:forbidden)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end
end
