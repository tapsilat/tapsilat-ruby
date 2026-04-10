require 'spec_helper'

RSpec.describe Tapsilat::Resource::Organization do
  let(:client) { Tapsilat::Client.new }
  let(:organization) { client.organization }

  before do
    Tapsilat.configure do |config|
      config.base_url = 'https://panel.tapsilat.dev/api/v1'
      config.api_token = 'test_token'
    end
  end

  describe '#settings' do
    it 'gets organization settings' do
      stub_request(:get, 'https://panel.tapsilat.dev/api/v1/organization/settings')
        .with(
          headers: {
            'Authorization' => 'Bearer test_token',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(
          status: 200,
          body: {
            organization_name: 'Test Organization',
            currency: 'TRY',
            locale: 'tr'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = organization.settings

      expect(result['organization_name']).to eq('Test Organization')
      expect(result['currency']).to eq('TRY')
      expect(result['locale']).to eq('tr')
    end
  end
end
