require_relative 'lib/tapsilat'
require 'dotenv/load'

# Configure Tapsilat
Tapsilat.configure do |config|
  config.base_url = ENV['TAPSILAT_BASE_URL'] || 'https://panel.tapsilat.dev/api/v1'
  config.api_token = ENV['TAPSILAT_API_KEY']
end

client = Tapsilat::Client.new

puts "=== Tapsilat Ruby SDK Example (Modern Architecture) ==="

begin
  # 1. Organization Settings
  settings = client.organization.settings
  puts "✅ Organization Settings: #{settings['organization_name']}"

  # 2. Build and Create Order
  buyer = Tapsilat::BuyerDTO.new(
    name: 'Ruby',
    surname: 'Tester',
    email: 'ruby.tester@example.com',
    gsm_number: '+905001234567',
    identity_number: '11111111111'
  )

  order_req = client.orders.build_order(
    amount: 100.0,
    currency: 'TRY',
    locale: 'tr',
    buyer: buyer,
    conversation_id: "RUBY_EXAMPLE_#{Time.now.to_i}"
  )

  # Add basket items
  order_req.basket_items = [
    Tapsilat::BasketItemDTO.new(id: 'P1', name: 'Premium Service', price: 100.0, quantity: 1, item_type: 'VIRTUAL')
  ]

  order_res = client.orders.create(order_req)
  puts "✅ Order Created: #{order_res.reference_id}"
  puts "🔗 Checkout URL: #{order_res.checkout_url}"

  # 3. List Subscriptions
  subs = client.subscriptions.list(per_page: 5)
  puts "✅ Subscriptions listed. Count: #{subs['rows']&.size || 0}"

rescue => e
  puts "❌ Example failed: #{e.message}"
  puts e.backtrace.first(5)
end
