require_relative 'lib/tapsilat'
require 'json'
require 'time'
require 'fileutils'

def load_env
  env_path = File.expand_path('.env', __dir__)
  if File.exist?(env_path)
    File.readlines(env_path).each do |line|
      next if line.strip.empty? || line.start_with?('#')
      key, value = line.strip.split('=', 2)
      ENV[key.strip] = value.strip if key && value
    end
  end
end

load_env
api_key = ENV['TAPSILAT_API_KEY'] || ENV['TAPSILAT_BEARER_TOKEN']

if api_key.nil? || api_key.empty?
  puts "❌ TAPSILAT_API_KEY not found in .env!"
  exit 1
end

# Use the new Client architecture
client = Tapsilat::Client.new(api_key)

RESULTS_DIR = 'test_results'
FileUtils.mkdir_p(RESULTS_DIR)

def log_result(scenario, input, output)
  File.write("#{RESULTS_DIR}/scenario_#{scenario}_input.json", JSON.pretty_generate(input || {}))
  File.write("#{RESULTS_DIR}/scenario_#{scenario}_output.json", JSON.pretty_generate(output || {}))
end

puts "\n🚀 Starting Ruby SDK Parity Verification (New Architecture)"
puts "============================================================"

begin
  conv_id = "RUBY_CONV_#{Time.now.to_i}"
  
  # 1. Basic Order
  buyer = Tapsilat::BuyerDTO.new(
    name: 'Ruby',
    surname: 'User',
    email: 'ruby@example.com',
    gsm_number: '+905001112233',
    identity_number: '11111111111'
  )
  
  order_req = client.orders.build_order(
    amount: 1.0,
    currency: 'TRY',
    locale: 'tr',
    buyer: buyer,
    conversation_id: conv_id,
    payment_success_url: 'https://example.com/success',
    payment_failure_url: 'https://example.com/failure'
  )
  
  res = client.orders.create(order_req)
  ref_id = res.reference_id
  puts "✅ Scenario 1: Basic Order Created: #{ref_id}"
  log_result('1__basic_order', order_req.to_h, res.to_h)

  # 2. Order with Basket Items
  basket_items = [
    Tapsilat::BasketItemDTO.new(id: 'ITEM1', name: 'Item 1', price: 0.5, quantity: 1, item_type: 'PHYSICAL'),
    Tapsilat::BasketItemDTO.new(id: 'ITEM2', name: 'Item 2', price: 0.5, quantity: 1, item_type: 'PHYSICAL')
  ]
  
  order_req_basket = client.orders.build_order(
    amount: 1.0,
    currency: 'TRY',
    locale: 'tr',
    buyer: buyer,
    basket_items: basket_items,
    conversation_id: "#{conv_id}_BASKET"
  )
  
  res_basket = client.orders.create(order_req_basket)
  puts "✅ Scenario 2: Order with Basket Items Created: #{res_basket.reference_id}"
  log_result('2__order_with_basket_items', order_req_basket.to_h, res_basket.to_h)

  # 3. Order with Addresses
  address = Tapsilat::AddressDTO.new(
    contact_name: 'Ruby User',
    city: 'Istanbul',
    country: 'Turkey',
    address: 'Uskudar',
    zip_code: '34000',
    vat_number: '11111111111'
  )
  
  order_req_addr = client.orders.build_order(
    amount: 1.0,
    currency: 'TRY',
    locale: 'tr',
    buyer: buyer,
    billing_address: address,
    shipping_address: address,
    three_d_force: true
  )
  
  res_addr = client.orders.create(order_req_addr)
  puts "✅ Scenario 3: Order with Addresses Created: #{res_addr.reference_id}"
  log_result('3__order_with_addresses', order_req_addr.to_h, res_addr.to_h)

  # --- Subscription ---
  sub_user = Tapsilat::SubscriptionUserDTO.new(
    first_name: 'Ruby',
    last_name: 'Sub',
    email: 'ruby.sub@example.com',
    phone: '+905001112233'
  )
  
  sub_req = Tapsilat::SubscriptionCreateRequest.new(
    amount: 10.0,
    currency: 'TRY',
    cycle: 1,
    period: 1,
    payment_date: 1,
    title: 'Ruby Monthly Plan',
    user: sub_user,
    external_reference_id: "RUBY_SUB_#{Time.now.to_i}"
  )
  
  sub_res = client.subscriptions.create(sub_req.to_h)
  puts "✅ Scenario 4: Subscription Created: #{sub_res['reference_id']}"
  log_result('4__subscription_create', sub_req.to_h, sub_res)

rescue => e
  puts "❌ Verification Failed: #{e.message}"
  puts e.backtrace.first(10)
end

puts "\nVerification completed! Results in #{RESULTS_DIR}/"
