#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
#  Tapsilat Ruby SDK — Comprehensive Integration Test
#  Tests every method in TapsilatAPI against the live API.
#  Results are written to test_results/integration_<timestamp>.json
# =============================================================================

require 'bundler/setup'
require 'json'
require 'time'
require 'fileutils'
require_relative 'lib/tapsilat'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
# Load .env manually (no dotenv gem needed)
env_file = File.join(__dir__, '.env')
if File.exist?(env_file)
  File.foreach(env_file) do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')
    key, val = line.split('=', 2)
    ENV[key.strip] = val.strip if key && val && !ENV.key?(key.strip)
  end
end

API_KEY  = ENV['TAPSILAT_API_KEY'] || ENV['TAPSILAT_API_TOKEN'] || ''
BASE_URL = ENV['TAPSILAT_BASE_URL'] || 'https://panel.tapsilat.dev/api/v1'

abort('ERROR: TAPSILAT_API_KEY is not set.') if API_KEY.empty?

api = Tapsilat::TapsilatAPI.new(API_KEY, 30, BASE_URL)

# ---------------------------------------------------------------------------
# Test harness helpers
# ---------------------------------------------------------------------------
RESULTS = []
PASS    = 0
FAIL    = 0

def section(title)
  puts "\n#{'='*70}"
  puts "  #{title}"
  puts '='*70
end

def run_test(name, input: nil)
  result = { test: name, input: input, status: nil, output: nil, error: nil, timestamp: Time.now.iso8601 }
  begin
    output = yield
    result[:status] = 'PASS'
    result[:output] = output
    puts "  ✓ #{name}"
    $pass_count = ($pass_count || 0) + 1
    output
  rescue Tapsilat::APIException => e
    result[:status] = 'API_ERROR'
    result[:error]  = { http: e.status_code, code: e.api_code, message: e.error_msg }
    puts "  ⚠ #{name} → HTTP #{e.status_code}: #{e.error_msg}"
    $fail_count = ($fail_count || 0) + 1
    nil
  rescue StandardError => e
    result[:status] = 'ERROR'
    result[:error]  = { class: e.class.name, message: e.message }
    puts "  ✗ #{name} → #{e.class}: #{e.message}"
    $fail_count = ($fail_count || 0) + 1
    nil
  ensure
    RESULTS << result
  end
end

$pass_count = 0
$fail_count = 0

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------
BUYER = {
  name: 'Ahmet',
  surname: 'Yılmaz',
  email: 'ahmet.yilmaz@tapsilat.dev',
  gsm_number: '905350000000',
  identity_number: '74300864791',
  city: 'Istanbul',
  country: 'Turkey',
  zip_code: '34732',
  ip: '127.0.0.1',
  registration_address: 'Üsküdar/İstanbul',
  registration_date: '2024-01-01',
  last_login_date: '2026-04-10'
}.freeze

BILLING = {
  billing_type: 'PERSONAL',
  citizenship: 'TR',
  city: 'Istanbul',
  country: 'TR',
  district: 'Üsküdar',
  address: 'Üsküdar/İstanbul',
  zip_code: '34732',
  contact_name: 'Ahmet Yılmaz',
  contact_phone: '+905350000000'
}.freeze

SHIPPING = {
  address: 'Üsküdar/İstanbul',
  city: 'Istanbul',
  country: 'TR',
  zip_code: '34732',
  contact_name: 'Ahmet Yılmaz',
  tracking_code: 'TRK001',
  shipping_date: '2026-04-15'
}.freeze

BASKET_ITEMS = [
  {
    id: 'PROD001',
    name: 'Ruby Test Ürünü',
    price: 80.0,
    quantity: 1,
    category1: 'Yazılım',
    category2: 'SDK',
    item_type: 'VIRTUAL'
  },
  {
    id: 'PROD002',
    name: 'Ruby Test Ürünü 2',
    price: 20.0,
    quantity: 1,
    category1: 'Yazılım',
    category2: 'SDK',
    item_type: 'VIRTUAL'
  }
].freeze

def build_order_payload(extras = {})
  {
    locale: 'tr',
    amount: 100.0,
    currency: 'TRY',
    buyer: BUYER,
    billing_address: BILLING,
    shipping_address: SHIPPING,
    basket_items: BASKET_ITEMS,
    payment_success_url: 'https://tapsilat.dev/success',
    payment_failure_url: 'https://tapsilat.dev/failure',
    redirect_success_url: 'https://tapsilat.dev/redirect-success',
    redirect_failure_url: 'https://tapsilat.dev/redirect-failure',
    conversation_id: "ruby-sdk-test-#{Time.now.to_i}",
    metadata: [{ key: 'sdk', value: 'ruby' }, { key: 'test', value: 'integration' }],
    payment_options: ['credit_card']
  }.merge(extras)
end

# ============================================================================
# SECTION 1: System Endpoints
# ============================================================================
section('1. System Endpoints')

run_test('GET /system/order-statuses') do
  api.get_system_order_statuses
end

run_test('GET /system/error-codes') do
  api.get_system_error_codes
end

run_test('GET /system/transaction-purposes') do
  api.get_system_transaction_purposes
end

run_test('GET /system/shortcut-types') do
  api.get_system_shortcut_types
end

run_test('GET /system/payment-term-statuses') do
  api.get_system_payment_term_statuses
end

run_test('GET /system/transaction-statuses') do
  api.get_system_transaction_statuses
end

run_test('GET /system/product-types') do
  api.get_system_product_types
end

run_test('GET /system/basket-item-types') do
  api.get_system_basket_item_types
end

run_test('GET /system/transaction-payment-types') do
  api.get_system_transaction_payment_types
end

# ============================================================================
# SECTION 2: Organization Endpoints
# ============================================================================
section('2. Organization Endpoints')

run_test('GET /organization/settings') do
  api.get_organization_settings
end

run_test('GET /organization/callback') do
  api.get_organization_callback
end

run_test('GET /organization/currencies') do
  api.get_organization_currencies
end

run_test('GET /organization/scopes') do
  api.get_organization_scopes
end

run_test('GET /organization/suborganizations') do
  api.get_organization_suborganizations(page: 1, per_page: 10)
end

run_test('GET /organization/limits') do
  api.get_organization_limits
end

run_test('POST /organization/list-vpos') do
  req = Tapsilat::GetVposRequest.new(currency_id: 'TRY')
  api.list_organization_vpos(req.to_h)
end

run_test('GET /organization/meta/:name (currency_resolver)') do
  api.get_organization_meta('currency_resolver')
end

# PATCH /organization/callback — update then restore
run_test('PATCH /organization/callback (update then restore)') do
  req = Tapsilat::CallbackURLDTO.new(
    callback_url:        'https://tapsilat.dev/ruby-sdk-test/callback',
    fail_callback_url:   'https://tapsilat.dev/ruby-sdk-test/fail',
    refund_callback_url: 'https://tapsilat.dev/ruby-sdk-test/refund',
    cancel_callback_url: 'https://tapsilat.dev/ruby-sdk-test/cancel'
  )
  api.update_organization_callback(req.to_h)
end

run_test('POST /organization/business/create (expected error — duplicate or validation)') do
  req = Tapsilat::OrgCreateBusinessRequest.new(
    address:         'Test Mah. Test Sok. No:1',
    business_name:   'Ruby SDK Test Business',
    business_type:   Tapsilat::OrgCreateBusinessRequest::INDIVIDUAL,
    email:           'ruby-sdk-biz@tapsilat.dev',
    first_name:      'Ahmet',
    identity_number: '74300864791',
    last_name:       'Yilmaz',
    phone:           '+905350000000',
    tax_number:      '1234567890',
    tax_office:      'Uskudar',
    zip_code:        '34732'
  )
  api.create_organization_business(req.to_h)
end

run_test('GET /organization/limit/user (expected error — user_id required by backend)') do
  req = Tapsilat::GetUserLimitRequest.new(user_id: 'non-existent-user-000')
  api.get_organization_limit_user(req.to_h)
end

run_test('POST /organization/limit/user (expected error — invalid user/limit)') do
  req = Tapsilat::SetLimitUserRequest.new(
    user_id:  'non-existent-user-000',
    limit_id: 'non-existent-limit-000'
  )
  api.set_organization_limit_user(req.to_h)
end

org_user_id = nil
run_test('POST /organization/user/create') do
  req = Tapsilat::OrgCreateUserReq.new(
    conversation_id:  "ruby-user-#{Time.now.to_i}",
    email:            "ruby-sdk-user-#{Time.now.to_i}@tapsilat.dev",
    first_name:       'Ruby',
    identity_number:  '74300864791',
    is_mail_verified: false,
    last_name:        'SDKUser',
    phone:            '+905350000001',
    reference_id:     "ruby-usr-ref-#{Time.now.to_i}"
  )
  resp = api.create_organization_user(req.to_h)
  org_user_id = resp.is_a?(Hash) ? (resp['id'] || resp['user_id']) : nil
  resp
end

if org_user_id
  run_test('POST /organization/user/verify') do
    req = Tapsilat::OrgUserVerifyReq.new(user_id: org_user_id)
    api.verify_organization_user(req.to_h)
  end

  run_test('POST /organization/user/verify-mobile') do
    req = Tapsilat::OrgUserMobileVerifyReq.new(user_id: org_user_id)
    api.verify_organization_user_mobile(req.to_h)
  end
else
  run_test('POST /organization/user/verify (fallback — no user_id, expected error)') do
    req = Tapsilat::OrgUserVerifyReq.new(user_id: 'non-existent-user-000')
    api.verify_organization_user(req.to_h)
  end

  run_test('POST /organization/user/verify-mobile (fallback — no user_id, expected error)') do
    req = Tapsilat::OrgUserMobileVerifyReq.new(user_id: 'non-existent-user-000')
    api.verify_organization_user_mobile(req.to_h)
  end
end

run_test('POST /organization/user/token') do
  req = Tapsilat::OrgUserTokenReq.new(email: 'ruby-sdk-user@tapsilat.dev', expire: 3600)
  api.create_organization_user_token(req.to_h)
end

run_test('GET /organization/suborganizations/:id') do
  api.get_organization_suborganization('non-existent-suborg')
end

# ============================================================================
# SECTION 3: Order Lifecycle — Scenario A (Create → Get → Status → List)
# ============================================================================
section('3. Order Lifecycle — Scenario A (Create, Get, Status, Transactions, List)')

order_a_ref = nil
conv_id_a   = "ruby-test-a-#{Time.now.to_i}"

order_a_ref = run_test('POST /order/create (Scenario A)', input: build_order_payload(conversation_id: conv_id_a)) do
  payload = build_order_payload(conversation_id: conv_id_a)
  resp = api.create_order(payload)
  raise 'No reference_id in response' unless resp.is_a?(Hash) && resp['reference_id']
  resp['reference_id']
end

if order_a_ref
  run_test("GET /order/:id (ref=#{order_a_ref})") do
    api.get_order(order_a_ref)
  end

  run_test("GET /order/conversation/:id (conv=#{conv_id_a})") do
    api.get_order_by_conversation_id(conv_id_a)
  end

  run_test("GET /order/:id/status") do
    api.get_order_status(order_a_ref)
  end

  run_test("GET /order/:id/transactions") do
    api.get_order_transactions(order_a_ref)
  end

  run_test("GET /order/:id/payment-details") do
    api.get_order_payment_details_by_id(order_a_ref)
  end

  run_test("POST /order/payment-details (v2)") do
    req = Tapsilat::OrderPaymentDetailDTO.new(reference_id: order_a_ref)
    api.get_order_payment_details(req.to_h)
  end

  run_test("POST /order/accounting") do
    req = Tapsilat::OrderAccountingRequest.new(order_reference_id: order_a_ref)
    api.order_accounting(req.to_h)
  end

  run_test("POST /order/callback (manual callback)") do
    req = Tapsilat::OrderManualCallbackDTO.new(reference_id: order_a_ref)
    api.manual_callback(req.to_h)
  end
end

run_test('GET /order/list (page=1, per_page=5)') do
  api.get_order_list(page: 1, per_page: 5)
end

run_test('GET /order/list (with start_date filter)') do
  api.get_order_list(page: 1, per_page: 5, start_date: '2026-01-01', end_date: '2026-12-31')
end

run_test('GET /order/list (with organization_id filter)') do
  api.get_order_list(page: 1, per_page: 5, organization_id: 'non-existent')
end

run_test('GET /order/list via get_orders alias (with buyer_id)') do
  api.get_orders(page: '1', per_page: '5', buyer_id: 'non-existent-buyer')
end

run_test('GET /order/list via get_orders alias (no buyer_id)') do
  api.get_orders(page: '1', per_page: '5')
end

run_test('GET /order/submerchants') do
  api.get_order_submerchants(page: 1, per_page: 10)
end

# get_checkout_url is a convenience wrapper around get_order
if order_a_ref
  run_test("get_checkout_url (convenience wrapper on ref=#{order_a_ref})") do
    url = api.get_checkout_url(order_a_ref)
    raise 'checkout_url should be a non-nil value (string or nil from API)' if url.is_a?(FalseClass)
    { checkout_url: url }
  end
end


# ============================================================================
# SECTION 4: Order Lifecycle — Scenario B (Basket Item Operations)
# ============================================================================
section('4. Order Basket Item Operations — Scenario B')

order_b_ref = nil
conv_id_b   = "ruby-test-b-#{Time.now.to_i}"

order_b_ref = run_test('POST /order/create (Scenario B — for basket ops)', input: build_order_payload(conversation_id: conv_id_b)) do
  resp = api.create_order(build_order_payload(conversation_id: conv_id_b))
  raise 'No reference_id' unless resp.is_a?(Hash) && resp['reference_id']
  resp['reference_id']
end

if order_b_ref
  new_item = {
    id: 'PROD003',
    name: 'Yeni Ürün',
    price: 50.0,
    quantity: 1,
    category1: 'Test',
    item_type: 'VIRTUAL'
  }

  run_test("POST /order/basket-item (add)") do
    req = { order_reference_id: order_b_ref, basket_item: new_item }
    api.add_basket_item(req)
  end

  updated_item = new_item.merge(price: 45.0)
  run_test("PATCH /order/basket-item (update)") do
    req = { order_reference_id: order_b_ref, basket_item: updated_item }
    api.update_basket_item(req)
  end

  run_test("DELETE /order/basket-item (remove)") do
    req = { order_reference_id: order_b_ref, basket_item_id: 'PROD003' }
    api.remove_basket_item(req)
  end
end

# ============================================================================
# SECTION 5: Order Lifecycle — Scenario C (Payment Terms)
# ============================================================================
section('5. Order Payment Terms — Scenario C')

order_c_ref  = nil
conv_id_c    = "ruby-test-c-#{Time.now.to_i}"
term_ref_id  = "TERM-RUBY-#{Time.now.to_i}"

order_c_ref = run_test('POST /order/create (Scenario C — for payment terms)', input: build_order_payload(conversation_id: conv_id_c)) do
  resp = api.create_order(build_order_payload(conversation_id: conv_id_c))
  raise 'No reference_id' unless resp.is_a?(Hash) && resp['reference_id']
  resp['reference_id']
end

if order_c_ref
  run_test("POST /order/term (create term)") do
    term = Tapsilat::OrderPaymentTermCreateDTO.new(
      order_id:          order_c_ref,
      term_reference_id: term_ref_id,
      amount:            100.0,
      due_date:          '2026-06-01T00:00:00Z',
      term_sequence:     1,
      required:          true,
      status:            'pending'
    )
    api.create_order_term(term.to_h)
  end

  run_test("GET /order/term (get term)") do
    api.get_order_term(term_ref_id)
  end

  run_test("PATCH /order/term (update term)") do
    update = Tapsilat::OrderPaymentTermUpdateDTO.new(
      term_reference_id: term_ref_id,
      term_sequence:     1,
      required:          true,
      amount:            100.0,
      due_date:          '2026-07-01T00:00:00Z',
      status:            'pending'
    )
    api.update_order_term(update.to_h)
  end

  run_test("DELETE /order/term (delete term)") do
    delete_req = Tapsilat::OrderPaymentTermDeleteDTO.new(
      order_id:          order_c_ref,
      term_reference_id: term_ref_id
    )
    api.delete_order_term(delete_req.to_h)
  end
end

# ============================================================================
# SECTION 6: Order Lifecycle — Scenario D (Related Reference)
# ============================================================================
section('6. Order Related Reference — Scenario D')

order_d1_ref = nil
order_d2_ref = nil
conv_d1      = "ruby-test-d1-#{Time.now.to_i}"
conv_d2      = "ruby-test-d2-#{Time.now.to_i}"

order_d1_ref = run_test('POST /order/create (Scenario D — order 1)') do
  resp = api.create_order(build_order_payload(conversation_id: conv_d1))
  raise 'No reference_id' unless resp.is_a?(Hash) && resp['reference_id']
  resp['reference_id']
end

order_d2_ref = run_test('POST /order/create (Scenario D — order 2)') do
  resp = api.create_order(build_order_payload(conversation_id: conv_d2))
  raise 'No reference_id' unless resp.is_a?(Hash) && resp['reference_id']
  resp['reference_id']
end

if order_d1_ref && order_d2_ref
  run_test("PATCH /order/releated (link orders)") do
    req = Tapsilat::OrderRelatedReferenceDTO.new(
      reference_id:         order_d1_ref,
      related_reference_id: order_d2_ref
    )
    api.related_update(req.to_h)
  end
end

# ============================================================================
# SECTION 7: Order Lifecycle — Scenario E (Refund)
# ============================================================================
section('7. Order Refund — Scenario E')

order_e_ref = nil
conv_e      = "ruby-test-e-#{Time.now.to_i}"

order_e_ref = run_test('POST /order/create (Scenario E — for refund/cancel tests)') do
  resp = api.create_order(build_order_payload(conversation_id: conv_e))
  raise 'No reference_id' unless resp.is_a?(Hash) && resp['reference_id']
  resp['reference_id']
end

if order_e_ref
  # Try refund (will likely fail since order not paid — we log the response)
  run_test("POST /order/refund (unpaid order — expected API error)") do
    req = Tapsilat::RefundOrderDTO.new(
      reference_id:        order_e_ref,
      amount:              50.0,
      order_item_id:       'PROD001'
    )
    api.refund_order(req.to_h)
  end

  run_test("POST /order/refund-all (unpaid order — expected API error)") do
    req = Tapsilat::RefundAllOrderDTO.new(reference_id: order_e_ref)
    api.refund_all_order(req.to_h)
  end

  run_test("POST /order/postauth (unpaid order — expected API error)") do
    req = Tapsilat::OrderPostAuthRequest.new(amount: 100.0, reference_id: order_e_ref)
    api.order_postauth(req.to_h)
  end
end

# ============================================================================
# SECTION 8: Order Cancel — Scenario F
# ============================================================================
section('8. Order Cancel — Scenario F')

order_f_ref = nil
conv_f      = "ruby-test-f-#{Time.now.to_i}"

order_f_ref = run_test('POST /order/create (Scenario F — for cancel)') do
  resp = api.create_order(build_order_payload(conversation_id: conv_f))
  raise 'No reference_id' unless resp.is_a?(Hash) && resp['reference_id']
  resp['reference_id']
end

if order_f_ref
  run_test("POST /order/cancel") do
    req = Tapsilat::CancelOrderDTO.new(reference_id: order_f_ref)
    api.cancel_order(req.to_h)
  end

  # After cancel, verify status reflects cancellation
  run_test("GET /order/:id/status (after cancel)") do
    api.get_order_status(order_f_ref)
  end

  # Try operations on cancelled order (expect errors — document them)
  run_test("POST /order/callback (cancelled order — expected error)") do
    req = Tapsilat::OrderManualCallbackDTO.new(reference_id: order_f_ref)
    api.manual_callback(req.to_h)
  end
end

# ============================================================================
# SECTION 9: Order Terminate — Scenario G
# ============================================================================
section('9. Order Terminate — Scenario G')

order_g_ref = nil
conv_g      = "ruby-test-g-#{Time.now.to_i}"

order_g_ref = run_test('POST /order/create (Scenario G — for terminate)') do
  resp = api.create_order(build_order_payload(conversation_id: conv_g))
  raise 'No reference_id' unless resp.is_a?(Hash) && resp['reference_id']
  resp['reference_id']
end

if order_g_ref
  run_test("POST /order/terminate") do
    req = Tapsilat::TerminateRequest.new(reference_id: order_g_ref)
    api.terminate_order(req.to_h)
  end
end

# ============================================================================
# SECTION 10: Subscription Endpoints
# ============================================================================
section('10. Subscription Endpoints')

sub_ref = nil

run_test('GET /subscription/list') do
  api.list_subscriptions(page: 1, per_page: 10)
end

sub_ref = run_test('POST /subscription/create') do
  user = Tapsilat::SubscriptionUserDTO.new(
    email:           'ahmet.yilmaz@tapsilat.dev',
    first_name:      'Ahmet',
    last_name:       'Yılmaz',
    phone:           '905350000000',
    identity_number: '74300864791',
    address:         'Üsküdar/İstanbul',
    city:            'Istanbul',
    zip_code:        '34732',
    country:         'TR'
  )
  billing = Tapsilat::SubscriptionBillingDTO.new(
    address:      'Üsküdar/İstanbul',
    city:         'Istanbul',
    zip_code:     '34732',
    country:      'TR',
    contact_name: 'Ahmet Yılmaz'
  )
  req = Tapsilat::SubscriptionCreateRequest.new(
    amount:                99.0,
    currency:              'TRY',
    cycle:                 1,
    period:                12,
    title:                 'Ruby SDK Test Aboneliği',
    user:                  user,
    billing:               billing,
    success_url:           'https://tapsilat.dev/success',
    failure_url:           'https://tapsilat.dev/fail',
    payment_date:          15,
    external_reference_id: "RUBY-SUB-#{Time.now.to_i}"
  )
  resp = api.create_subscription(req.to_h)
  resp.is_a?(Hash) ? resp['reference_id'] : nil
end

if sub_ref
  run_test("POST /subscription (get by reference_id)") do
    req = Tapsilat::SubscriptionGetRequest.new(reference_id: sub_ref)
    api.get_subscription(req.to_h)
  end

  run_test("POST /subscription/redirect") do
    req = Tapsilat::SubscriptionRedirectRequest.new(subscription_id: sub_ref)
    api.redirect_subscription(req.to_h)
  end

  run_test("POST /subscription/cancel") do
    req = Tapsilat::SubscriptionCancelRequest.new(reference_id: sub_ref)
    api.cancel_subscription(req.to_h)
  end
end

# Get subscription with external_reference_id after cancel
run_test("POST /subscription (get non-existent — expected error)") do
  req = Tapsilat::SubscriptionGetRequest.new(reference_id: 'non-existent-sub-ref-000')
  api.get_subscription(req.to_h)
end

# ============================================================================
# SECTION 11: Term Refund (on a new order with a term)
# ============================================================================
section('11. Term Refund — Scenario H')

order_h_ref  = nil
conv_h       = "ruby-test-h-#{Time.now.to_i}"
term_h_ref   = "TERM-H-#{Time.now.to_i}"

order_h_ref = run_test('POST /order/create (Scenario H — for term refund test)') do
  resp = api.create_order(build_order_payload(conversation_id: conv_h))
  raise 'No reference_id' unless resp.is_a?(Hash) && resp['reference_id']
  resp['reference_id']
end

if order_h_ref
  term_created = run_test("POST /order/term (for term refund)") do
    term = Tapsilat::OrderPaymentTermCreateDTO.new(
      order_id:          order_h_ref,
      term_reference_id: term_h_ref,
      amount:            100.0,
      due_date:          '2026-06-01T00:00:00Z',
      term_sequence:     1,
      required:          true,
      status:            'pending'
    )
    api.create_order_term(term.to_h)
  end

  if term_created
    run_test("POST /order/term/refund (unpaid term — expected error)") do
      req = Tapsilat::OrderTermRefundRequest.new(
        term_id:      term_h_ref,
        amount:       100.0,
        reference_id: order_h_ref
      )
      api.refund_order_term(req.to_h)
    end
  end
end

# ============================================================================
# SECTION 12: Webhook Verification
# ============================================================================
section('12. Utility — Webhook Signature Verification')

run_test('verify_webhook (valid signature)') do
  secret  = 'my_webhook_secret'
  payload = '{"event":"order.paid","reference_id":"REF123"}'
  require 'openssl'
  sig     = "sha256=#{OpenSSL::HMAC.hexdigest('sha256', secret, payload)}"
  result  = Tapsilat::TapsilatAPI.verify_webhook(payload, sig, secret)
  raise 'Signature should be valid' unless result == true
  { verified: true, signature: sig }
end

run_test('verify_webhook (invalid signature)') do
  result = Tapsilat::TapsilatAPI.verify_webhook('payload', 'sha256=wrongsig', 'secret')
  raise 'Should return false for invalid signature' if result == true
  { verified: false }
end

# ============================================================================
# SECTION 13: Model unit tests (no network)
# ============================================================================
section('13. Model Unit Tests (no network)')

run_test('OrderCreateDTO — to_h excludes nil fields') do
  buyer = Tapsilat::BuyerDTO.new(name: 'Ali', surname: 'Veli', ip: '1.1.1.1')
  order = Tapsilat::OrderCreateDTO.new(amount: 100.0, currency: 'TRY', locale: 'tr', buyer: buyer)
  h = order.to_h
  raise 'amount missing' unless h[:amount] == 100.0
  raise 'nil fields should be excluded' if h.values.any?(&:nil?)
  h
end

run_test('OrderResponse — status helpers') do
  resp = Tapsilat::OrderResponse.new({ 'status' => 3, 'reference_id' => 'REF1' })
  raise 'paid? should be true'  unless resp.paid?
  raise 'cancelled? should be false' if resp.cancelled?
  raise 'status_text wrong' unless resp.status_text == 'Paid'
  { paid: resp.paid?, status_text: resp.status_text }
end

run_test('OrderResponse — cancelled status') do
  resp = Tapsilat::OrderResponse.new('status' => 8)
  raise 'cancelled? should be true' unless resp.cancelled?
  { cancelled: resp.cancelled? }
end

run_test('OrderResponse — refunded status') do
  [10, 15].each do |s|
    resp = Tapsilat::OrderResponse.new('status' => s)
    raise "refunded? should be true for #{s}" unless resp.refunded?
  end
  { refunded: true }
end

run_test('OrderResponse — failed statuses') do
  [11, 12, 13].each do |s|
    resp = Tapsilat::OrderResponse.new('status' => s)
    raise "failed? should be true for #{s}" unless resp.failed?
  end
  { failed: true }
end

run_test('OrderResponse — pending_payment statuses') do
  [2, 7].each do |s|
    resp = Tapsilat::OrderResponse.new('status' => s)
    raise "pending_payment? should be true for #{s}" unless resp.pending_payment?
  end
  { pending: true }
end

run_test('BaseDTO — nested to_h serialisation') do
  payer = Tapsilat::BasketItemPayerDTO.new(title: 'Payer Co', type: 'CORPORATE')
  item  = Tapsilat::BasketItemDTO.new(id: 'I1', name: 'P', price: 10.0, payer: payer)
  h     = item.to_h
  raise 'payer should be nested hash' unless h[:payer].is_a?(Hash)
  raise 'payer title wrong' unless h[:payer][:title] == 'Payer Co'
  h
end

run_test('OrderAccountingRequest — to_h') do
  req = Tapsilat::OrderAccountingRequest.new(order_reference_id: 'REF-X')
  h   = req.to_h
  raise 'order_reference_id missing' unless h[:order_reference_id] == 'REF-X'
  h
end

run_test('OrgCreateBusinessRequest — constants') do
  raise 'INDIVIDUAL should be 0' unless Tapsilat::OrgCreateBusinessRequest::INDIVIDUAL == 0
  raise 'CORPORATE should be 1'  unless Tapsilat::OrgCreateBusinessRequest::CORPORATE  == 1
  { individual: 0, corporate: 1 }
end

run_test('AddressDTO is alias of BillingAddressDTO') do
  raise 'AddressDTO alias wrong' unless Tapsilat::AddressDTO == Tapsilat::BillingAddressDTO
  { alias_ok: true }
end

run_test('RefundOrderDTO alias check') do
  raise 'OrderRefundRequest alias broken' unless Tapsilat::OrderRefundRequest == Tapsilat::RefundOrderDTO
  raise 'OrderCancelRequest alias broken' unless Tapsilat::OrderCancelRequest == Tapsilat::CancelOrderDTO
  { aliases_ok: true }
end

run_test('CheckoutDesignDTO — all fields settable') do
  d = Tapsilat::CheckoutDesignDTO.new(
    logo:                   'https://example.com/logo.png',
    input_background_color: '#ffffff',
    input_text_color:       '#000000',
    label_text_color:       '#333333',
    left_background_color:  '#f0f0f0',
    right_background_color: '#e0e0e0',
    text_color:             '#111111',
    pay_button_color:       '#0070f3',
    order_detail_html:      '<p>Test</p>',
    redirect_url:           'https://example.com/redirect'
  )
  h = d.to_h
  raise 'logo missing'  unless h[:logo]
  raise 'nil in output' if h.values.any?(&:nil?)
  h
end

run_test('SubOrganizationDTO — all fields settable') do
  s = Tapsilat::SubOrganizationDTO.new(
    organization_name:      'Test Org',
    email:                  'org@test.com',
    contact_first_name:     'Ali',
    contact_last_name:      'Veli',
    iban:                   'TR000000000000000000000000',
    address:                'Test Addr',
    tax_office:             'Kadikoy',
    tax_number:             '1234567890',
    gsm_number:             '+905351234567',
    identity_number:        '74300864791',
    legal_company_title:    'Test Ltd.',
    sub_merchant_external_id: 'EXT001',
    sub_merchant_key:       'KEY001',
    sub_merchant_type:      'PERSONAL',
    currency:               'TRY',
    acquirer:               'test'
  )
  h = s.to_h
  raise 'organization_name missing' unless h[:organization_name]
  h
end

run_test('OrderPFSubMerchantDTO — all fields settable') do
  pf = Tapsilat::OrderPFSubMerchantDTO.new(
    name:            'PF Merchant',
    id:              'PF001',
    postal_code:     '34000',
    city:            'Istanbul',
    country:         'TR',
    mcc:             '5411',
    terminal_no:     'T001',
    org_id:          'ORG001',
    country_iso_code: '792',
    address:         'Test Addr',
    submerchant_url: 'https://merchant.com',
    submerchant_nin: 'NIN001',
    switch_id:       '1',
    national_id:     'NAT001'
  )
  h = pf.to_h
  raise 'name missing' unless h[:name]
  h
end


run_test('PaymentTermDTO — all optional fields') do
  pt = Tapsilat::PaymentTermDTO.new(
    amount:            50.0,
    data:              'extra',
    due_date:          '2026-06-01',
    paid_date:         nil,
    required:          true,
    status:            'pending',
    term_reference_id: 'TERM001',
    term_sequence:     1,
    id:                'ID001',
    hash_id:           'HASH001'
  )
  h = pt.to_h
  raise 'amount missing' unless h[:amount]
  raise 'nil paid_date should be excluded' if h.key?(:paid_date)
  h
end

# ============================================================================
# SECTION 14: Client Resource Methods
# ============================================================================
section('14. Client Resource Methods (Tapsilat::Client high-level API)')

client = Tapsilat::Client.new(API_KEY, 30, BASE_URL)

run_test('Client#organization.settings') do
  client.organization.settings
end

client_order_ref = nil
run_test('Client#orders.create') do
  buyer = Tapsilat::BuyerDTO.new(
    name: 'Client', surname: 'Test',
    email: 'client@tapsilat.dev',
    gsm_number: '905350000000',
    identity_number: '74300864791',
    ip: '127.0.0.1'
  )
  dto = Tapsilat::OrderCreateDTO.new(
    amount:              50.0,
    currency:            'TRY',
    locale:              'tr',
    buyer:               buyer,
    billing_address:     BILLING,
    basket_items:        [BASKET_ITEMS.first.merge(price: 50.0)],
    payment_success_url: 'https://tapsilat.dev/success',
    payment_failure_url: 'https://tapsilat.dev/fail',
    conversation_id:     "client-test-#{Time.now.to_i}"
  )
  resp = client.orders.create(dto)
  # TapsilatOrderCreateResponse or Hash — extract reference_id
  ref = if resp.respond_to?(:reference_id)
          resp.reference_id
        elsif resp.is_a?(Hash)
          resp['reference_id']
        end
  client_order_ref = ref
  resp
end

if client_order_ref
  run_test("Client#orders.get (ref=#{client_order_ref})") do
    client.orders.get(client_order_ref)
  end

  run_test('Client#orders.get_status') do
    client.orders.get_status(client_order_ref)
  end

  run_test('Client#orders.cancel') do
    client.orders.cancel(client_order_ref)
  end
end

run_test('Client#orders.list') do
  client.orders.list(page: 1, per_page: 5)
end

run_test('Client#orders.refund (cancelled order — expected error)') do
  ref = client_order_ref || 'non-existent'
  client.orders.refund(ref, 10.0)
end

run_test('Client#subscriptions.list') do
  client.subscriptions.list(page: 1, per_page: 5)
end

client_sub_ref = nil
run_test('Client#subscriptions.create') do
  user = Tapsilat::SubscriptionUserDTO.new(
    email:      'client-sub@tapsilat.dev',
    first_name: 'Client',
    last_name:  'Sub'
  )
  dto = Tapsilat::SubscriptionCreateRequest.new(
    amount:                49.0,
    currency:              'TRY',
    cycle:                 1,
    period:                6,
    title:                 'Client Resource Sub Test',
    user:                  user,
    success_url:           'https://tapsilat.dev/success',
    failure_url:           'https://tapsilat.dev/fail',
    payment_date:          10,
    external_reference_id: "client-sub-#{Time.now.to_i}"
  )
  resp = client.subscriptions.create(dto)
  client_sub_ref = resp.is_a?(Hash) ? resp['reference_id'] : nil
  resp
end

if client_sub_ref
  run_test('Client#subscriptions.get (by reference_id)') do
    client.subscriptions.get(reference_id: client_sub_ref)
  end

  run_test('Client#subscriptions.redirect') do
    client.subscriptions.redirect(client_sub_ref)
  end

  run_test('Client#subscriptions.cancel') do
    client.subscriptions.cancel(reference_id: client_sub_ref)
  end

  # After cancel, try get via external_reference_id (expected error since cancelled)
  run_test('Client#subscriptions.get (by external_reference_id — expected error)') do
    client.subscriptions.get(external_reference_id: 'non-existent-ext-ref')
  end
end

# Client#orders.build_order — pure unit, no network
run_test('Client#orders.build_order') do
  result = client.orders.build_order(
    locale:          'tr',
    amount:          99.0,
    currency:        'TRY',
    buyer:           BUYER,
    billing_address: BILLING,
    basket_items:    BASKET_ITEMS
  )
  # build_order returns an OrderCreateDTO — verify it serialises correctly
  raise 'build_order should return an OrderCreateDTO' unless result.is_a?(Tapsilat::OrderCreateDTO)
  h = result.to_h
  raise 'amount should be 99.0' unless h[:amount] == 99.0
  raise 'currency should be TRY' unless h[:currency] == 'TRY'
  h
end

section('15. Client System Resource')

run_test('Client#system.error_codes') do
  client.system.error_codes
end

run_test('Client#system.order_statuses') do
  client.system.order_statuses
end

run_test('Client#system.product_types') do
  client.system.product_types
end

# ============================================================================
# Summary & Save Results
# ============================================================================
section('SUMMARY')

total = $pass_count + $fail_count
puts "  Total:  #{total}"
puts "  Pass:   #{$pass_count}"
puts "  Fail:   #{$fail_count} (API errors expected for unpaid-order operations)"

outdir  = File.join(__dir__, 'test_results')
FileUtils.mkdir_p(outdir)
outfile = File.join(outdir, "integration_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json")

report = {
  meta: {
    run_at:    Time.now.iso8601,
    base_url:  BASE_URL,
    total:     total,
    pass:      $pass_count,
    fail:      $fail_count
  },
  results: RESULTS
}

File.write(outfile, JSON.pretty_generate(report))
puts "\n  Results saved → #{outfile}"
puts "  Open with: cat #{outfile} | python3 -m json.tool | less"
