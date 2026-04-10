require 'spec_helper'

RSpec.describe Tapsilat::Resource::Health do
  let(:client) { Tapsilat::Client.new }
  let(:health) { client.health }

  before do
    Tapsilat.configure do |config|
      config.base_url = 'https://panel.tapsilat.dev/api/v1'
      config.api_token = 'test_token'
    end
  end

  describe '#check' do
    it 'checks API health status' do
      stub_request(:get, 'https://panel.tapsilat.dev/api/v1/health')
        .with(
          headers: {
            'Authorization' => 'Bearer test_token',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(
          status: 200,
          body: { status: 'OK' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = health.check

      expect(result['status']).to eq('OK')
    end
  end
end
