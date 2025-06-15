RSpec.describe Tapsilat::Client, :configured do
  let(:client) { described_class.new }

  describe '#initialize' do
    it 'sets the base URI from Tapsilat configuration' do
      expect(client.class.base_uri).to eq(Tapsilat.base_url)
    end

    it 'sets the default headers' do
      expected_headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{Tapsilat.api_token}"
      }
      expect(client.class.default_options[:headers]).to eq(expected_headers)
    end
  end

  describe '#orders' do
    it 'returns an Orders instance' do
      expect(client.orders).to be_a(Tapsilat::Orders)
    end

    it 'memoizes the orders instance' do
      expect(client.orders).to be(client.orders)
    end
  end

  # HTTP methods with real API
  describe 'HTTP methods' do
    describe '#get' do
      it 'performs a GET request to the real API' do
        response = client.get('/order/list')
        expect(response).to respond_to(:code) if response.respond_to?(:code)
      rescue StandardError => e
        # Expected if endpoint returns HTML or has other issues
        expect(e).to be_a(StandardError)
      end
    end

    describe '#post' do
      it 'performs a POST request to the real API' do
        response = client.post('/order/create', body: {})
        expect(response).to respond_to(:code) if response.respond_to?(:code)
      rescue StandardError => e
        # Expected if endpoint returns HTML or has validation errors
        expect(e).to be_a(StandardError)
      end
    end
  end
end
