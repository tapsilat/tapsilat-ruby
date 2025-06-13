RSpec.describe Tapsilat::Client do
  describe '#initialize' do
    context 'when Tapsilat is not configured' do
      it 'raises ConfigurationError' do
        expect { described_class.new }.to raise_error(Tapsilat::ConfigurationError, 'Tapsilat not configured')
      end
    end

    context 'when Tapsilat is configured', :configured do
      it 'initializes successfully' do
        expect { described_class.new }.not_to raise_error
      end

      it 'sets proper headers' do
        client = described_class.new
        headers = client.class.headers

        expect(headers['Authorization']).to eq('Bearer test-token')
        expect(headers['Content-Type']).to eq('application/json')
        expect(headers['Accept']).to eq('application/json')
      end

      it 'sets base URI' do
        client = described_class.new
        expect(client.class.base_uri).to eq('https://api.tapsilat.com')
      end
    end
  end

  describe '#orders', :configured do
    let(:client) { described_class.new }

    it 'returns an Orders instance' do
      expect(client.orders).to be_a(Tapsilat::Orders)
    end

    it 'memoizes the orders instance' do
      expect(client.orders).to be(client.orders)
    end
  end

  describe 'HTTP methods', :configured do
    let(:client) { described_class.new }

    describe '#get' do
      context 'when request is successful' do
        before do
          stub_request(:get, 'https://api.tapsilat.com/test')
            .to_return(status: 200, body: '{"success": true}', headers: { 'Content-Type' => 'application/json' })
        end

        it 'returns parsed response' do
          response = client.get('/test')
          expect(response).to eq({ 'success' => true })
        end
      end

      context 'when request returns 401' do
        before do
          stub_request(:get, 'https://api.tapsilat.com/test')
            .to_return(status: 401, body: '{"error": "Unauthorized"}')
        end

        it 'raises Error with unauthorized message' do
          expect { client.get('/test') }.to raise_error(Tapsilat::Error, 'Unauthorized: Invalid API token')
        end
      end

      context 'when request returns 404' do
        before do
          stub_request(:get, 'https://api.tapsilat.com/test')
            .to_return(status: 404, body: '{"error": "Not Found"}')
        end

        it 'raises Error with not found message' do
          expect { client.get('/test') }.to raise_error(Tapsilat::Error, 'Resource not found')
        end
      end

      context 'when request returns 500' do
        before do
          stub_request(:get, 'https://api.tapsilat.com/test')
            .to_return(status: 500, body: '{"error": "Internal Server Error"}')
        end

        it 'raises Error with server error message' do
          expect { client.get('/test') }.to raise_error(Tapsilat::Error, 'Server error')
        end
      end

      context 'when request returns other error code' do
        before do
          stub_request(:get, 'https://api.tapsilat.com/test')
            .to_return(status: 422, body: '{"error": "Validation Error"}')
        end

        it 'raises Error with status code' do
          expect { client.get('/test') }.to raise_error(Tapsilat::Error, 'Request failed with status 422')
        end
      end
    end

    describe '#post' do
      context 'when request is successful' do
        before do
          stub_request(:post, 'https://api.tapsilat.com/test')
            .with(body: '{"data": "test"}')
            .to_return(status: 201, body: '{"created": true}', headers: { 'Content-Type' => 'application/json' })
        end

        it 'returns parsed response' do
          response = client.post('/test', body: '{"data": "test"}')
          expect(response).to eq({ 'created' => true })
        end
      end
    end

    describe '#put' do
      context 'when request is successful' do
        before do
          stub_request(:put, 'https://api.tapsilat.com/test')
            .with(body: '{"data": "updated"}')
            .to_return(status: 200, body: '{"updated": true}', headers: { 'Content-Type' => 'application/json' })
        end

        it 'returns parsed response' do
          response = client.put('/test', body: '{"data": "updated"}')
          expect(response).to eq({ 'updated' => true })
        end
      end
    end

    describe '#delete' do
      context 'when request is successful' do
        before do
          stub_request(:delete, 'https://api.tapsilat.com/test')
            .to_return(status: 204, body: '', headers: {})
        end

        it 'returns parsed response' do
          response = client.delete('/test')
          expect(response).to be_nil
        end
      end
    end
  end
end
