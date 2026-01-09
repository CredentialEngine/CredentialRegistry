RSpec.describe API::V1::Base do
  describe 'rescue exceptions' do
    before do
      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive(:test_response) { test_response }
      end
      get '/_test'
    end

    after do
      Grape::Endpoint.before_each nil
    end

    context 'ActiveRecord::RecordNotFound' do # rubocop:todo RSpec/ContextWording
      let(:test_response) { raise ActiveRecord::RecordNotFound }

      it { expect_status(404) }
      it { expect_json('errors.0', 'Record not found') }
    end

    context 'Grape::Exceptions::Validation' do # rubocop:todo RSpec/ContextWording
      let(:test_response) do
        # rubocop:todo RSpec/VerifiedDoubles
        err = double(params: [], message: 'Grape::Exceptions::Validation')
        # rubocop:enable RSpec/VerifiedDoubles
        raise Grape::Exceptions::ValidationErrors.new errors: [err]
      end

      it { expect_status(400) }
      it { expect_json('errors.0', /Grape::Exceptions::Validation/) }
    end

    context 'MetadataRegistry::BaseError' do # rubocop:todo RSpec/ContextWording
      let(:test_response) { raise MR::BaseError.new 'err', ['MR::Error'] }

      it { expect_status(400) }
      it { expect_json('errors.0', 'MR::Error') }
    end

    context 'JWT::VerificationError' do # rubocop:todo RSpec/ContextWording
      let(:test_response) { raise JWT::VerificationError, 'JWT::Error' }

      it { expect_status(400) }
      it { expect_json('errors.0', 'JWT::Error') }
    end

    context 'any other exception' do # rubocop:todo RSpec/ContextWording
      let(:test_response) { raise 'AnyError' }

      it { expect_status(500) }
      it { expect_json('errors.0', 'AnyError') }
    end
  end
end
