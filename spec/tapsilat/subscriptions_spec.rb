require 'spec_helper'

RSpec.describe Tapsilat::Subscriptions do
  let(:client) { Tapsilat::Client.new }
  let(:subscriptions) { described_class.new(client) }

  before do
    Tapsilat.configure do |config|
      config.base_url = 'https://panel.tapsilat.dev/api/v1'
      config.api_token = 'test_token'
    end
  end

  describe '#get' do
    it 'gets subscription details by reference_id' do
      stub_request(:post, 'https://panel.tapsilat.dev/api/v1/subscription')
        .with(
          body: { reference_id: 'sub-ref-123' }.to_json,
          headers: {
            'Authorization' => 'Bearer test_token',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(
          status: 200,
          body: {
            external_reference_id: 'ext-ref-123',
            is_active: true,
            title: 'My Subscription',
            payment_status: 'PAID'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = subscriptions.get(reference_id: 'sub-ref-123')

      expect(result['external_reference_id']).to eq('ext-ref-123')
      expect(result['is_active']).to be true
      expect(result['title']).to eq('My Subscription')
    end
  end

  describe '#cancel' do
    it 'cancels a subscription' do
      stub_request(:post, 'https://panel.tapsilat.dev/api/v1/subscription/cancel')
        .with(
          body: { reference_id: 'sub-ref-123' }.to_json,
          headers: {
            'Authorization' => 'Bearer test_token',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(
          status: 200,
          body: { success: true }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = subscriptions.cancel(reference_id: 'sub-ref-123')

      expect(result['success']).to be true
    end
  end

  describe '#create' do
    it 'creates a new subscription' do
      stub_request(:post, 'https://panel.tapsilat.dev/api/v1/subscription/create')
        .with(
          body: {
            title: 'Monthly Plan',
            amount: 100.0,
            currency: 'TRY',
            period: 30
          }.to_json,
          headers: {
            'Authorization' => 'Bearer test_token',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(
          status: 200,
          body: {
            reference_id: 'sub-ref-new',
            code: 100,
            message: 'Success'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = subscriptions.create(
        title: 'Monthly Plan',
        amount: 100.0,
        currency: 'TRY',
        period: 30
      )

      expect(result['reference_id']).to eq('sub-ref-new')
      expect(result['code']).to eq(100)
    end
  end

  describe '#list' do
    it 'lists subscriptions with pagination' do
      stub_request(:get, 'https://panel.tapsilat.dev/api/v1/subscription/list?page=1&per_page=10')
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
            page: 1,
            per_page: 10,
            items: [],
            total: 0
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = subscriptions.list(page: 1, per_page: 10)

      expect(result['page']).to eq(1)
      expect(result['per_page']).to eq(10)
      expect(result['items']).to eq([])
    end
  end

  describe '#redirect' do
    it 'gets redirect URL for a subscription' do
      stub_request(:post, 'https://panel.tapsilat.dev/api/v1/subscription/redirect')
        .with(
          body: { subscription_id: 'sub-ref-123' }.to_json,
          headers: {
            'Authorization' => 'Bearer test_token',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(
          status: 200,
          body: { url: 'https://redirect.example.com' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = subscriptions.redirect(subscription_id: 'sub-ref-123')

      expect(result['url']).to eq('https://redirect.example.com')
    end
  end
end
