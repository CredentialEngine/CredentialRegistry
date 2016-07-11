describe API::V1::Home do
  context 'GET /' do
    before(:each) do
      get '/'
    end

    context 'valid schema' do
      it { expect_status(:ok) }

      it 'renders the erb template' do
        expect(response.body).to match(/<!DOCTYPE html>\n<html lang='en-us'>.*/)
      end

      it 'renders the markdown' do
        expect(response.body).to match(/Metadata Registry API version 2.0/)
      end
    end
  end
end
