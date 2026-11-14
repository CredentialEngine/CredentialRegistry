RSpec.describe API::V1::Base do
  describe 'exception handling' do
    # Exercise the same handlers used by the application, without adding
    # test routes or mutable state to API::V1::Base.
    let(:test_api) do
      failure = exception

      Class.new(Grape::API) do
        include API::Defaults
        helpers SharedHelpers

        get '/_test' do
          raise failure
        end
      end
    end

    let(:response) { Rack::MockRequest.new(test_api).get('/_test') }
    let(:errors) { JSON.parse(response.body).fetch('errors') }

    context 'when a record is not found' do
      let(:exception) { ActiveRecord::RecordNotFound.new }

      it 'returns a 404 with a not-found error' do
        expect(response.status).to eq(404)
        expect(errors).to eq(['Record not found'])
      end
    end

    context 'when Grape validation fails' do
      let(:exception) do
        validation_error = Grape::Exceptions::Validation.new(
          params: ['errors'],
          message: 'Grape::Exceptions::Validation'
        )
        Grape::Exceptions::ValidationErrors.new(exceptions: [validation_error])
      end

      it 'returns a 400 with the validation message' do
        expect(response.status).to eq(400)
        expect(errors.first).to match(/Grape::Exceptions::Validation/)
      end
    end

    context 'when a registry error occurs' do
      let(:exception) { MR::BaseError.new('err', ['MR::Error']) }

      it 'returns a 400 with the registry error' do
        expect(response.status).to eq(400)
        expect(errors).to eq(['MR::Error'])
      end
    end

    context 'when JWT verification fails' do
      let(:exception) { JWT::VerificationError.new('JWT::Error') }

      it 'returns a 400 with the JWT error' do
        expect(response.status).to eq(400)
        expect(errors).to eq(['JWT::Error'])
      end
    end

    context 'when an unexpected exception occurs' do
      let(:exception) { RuntimeError.new('AnyError') }

      it 'returns a 500 with the exception message' do
        expect(response.status).to eq(500)
        expect(errors).to eq(['AnyError'])
      end
    end
  end
end
