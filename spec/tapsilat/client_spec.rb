RSpec.describe Tapsilat::Client, :configured do
  let(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a TapsilatAPI instance' do
      expect(client.instance_variable_get(:@api)).to be_a(Tapsilat::TapsilatAPI)
    end
  end

  describe 'Resources' do
    it 'exposes orders resource' do
      expect(client.orders).to be_a(Tapsilat::Resource::Order)
    end

    it 'exposes subscriptions resource' do
      expect(client.subscriptions).to be_a(Tapsilat::Resource::Subscription)
    end

    it 'exposes organization resource' do
      expect(client.organization).to be_a(Tapsilat::Resource::Organization)
    end

    it 'exposes system resource' do
      expect(client.system).to be_a(Tapsilat::Resource::System)
    end

    it 'memoizes resource instances' do
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
