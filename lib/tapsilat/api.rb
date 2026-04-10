require 'httparty'
require 'json'
require 'openssl'

module Tapsilat
  class TapsilatAPI
    include HTTParty

    def initialize(api_key = '', timeout = 10, base_url = 'https://panel.tapsilat.dev/api/v1')
      @api_key = api_key
      @timeout = timeout
      @base_url = base_url.gsub(/\/+$/, '')
      
      self.class.base_uri @base_url
      self.class.headers({
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      })
      self.class.default_timeout @timeout
    end

    def _make_request(method, endpoint, params: nil, body: nil)
      options = {}
      options[:query] = params if params
      options[:body] = body.to_json if body
      
      response = self.class.send(method.downcase, endpoint, options)
      handle_response(response)
    rescue StandardError => e
      raise Error, e.message unless e.is_a?(APIException)
      raise e
    end

    # --- Order Endpoints ---

    def create_order(order_data)
      _make_request('POST', '/order/create', body: order_data)
    end

    def pay_order(payment_data)
      _make_request('POST', '/order/pay', body: payment_data)
    end

    def pay_with_wallet(payment_data)
      _make_request('POST', '/order/pay-with-wallet', body: payment_data)
    end

    def pay_with_pin(payment_data)
      _make_request('POST', '/order/pay-with-pin', body: payment_data)
    end

    def order_accounting(request)
      _make_request('POST', '/order/accounting', body: request)
    end

    def order_postauth(request)
      _make_request('POST', '/order/postauth', body: request)
    end

    def get_order(reference_id)
      _make_request('GET', "/order/#{reference_id}")
    end

    def get_order_by_conversation_id(conversation_id)
      _make_request('GET', "/order/conversation/#{conversation_id}")
    end

    # Accepts any combination of:
    #   page:, per_page:, start_date:, end_date:,
    #   organization_id:, related_reference_id:, buyer_id:
    def get_order_list(
      page: 1,
      per_page: 10,
      start_date: nil,
      end_date: nil,
      organization_id: nil,
      related_reference_id: nil,
      buyer_id: nil,
      **extra
    )
      params = {
        page:                 page,
        per_page:             per_page,
        start_date:           start_date,
        end_date:             end_date,
        organization_id:      organization_id,
        related_reference_id: related_reference_id,
        buyer_id:             buyer_id
      }.merge(extra).reject { |_, v| v.nil? || v == '' }
      _make_request('GET', '/order/list', params: params)
    end

    # Alias matching Python SDK's get_orders(page, per_page, buyer_id)
    def get_orders(page: '1', per_page: '10', buyer_id: nil)
      params = { page: page, per_page: per_page }
      params[:buyer_id] = buyer_id if buyer_id
      _make_request('GET', '/order/list', params: params)
    end

    def get_order_submerchants(params = {})
      _make_request('GET', '/order/submerchants', params: params)
    end

    def get_checkout_url(reference_id)
      response = get_order(reference_id)
      response['checkout_url']
    end

    def cancel_order(request)
      _make_request('POST', '/order/cancel', body: request)
    end

    def refund_order(refund_data)
      _make_request('POST', '/order/refund', body: refund_data)
    end

    def refund_all_order(request)
      _make_request('POST', '/order/refund-all', body: request)
    end

    def get_order_payment_details(request)
      _make_request('POST', '/order/payment-details', body: request)
    end

    def get_order_payment_details_by_id(reference_id)
      _make_request('GET', "/order/#{reference_id}/payment-details")
    end

    def get_order_status(reference_id)
      _make_request('GET', "/order/#{reference_id}/status")
    end

    def get_order_transactions(reference_id)
      _make_request('GET', "/order/#{reference_id}/transactions")
    end

    def create_order_term(term)
      _make_request('POST', '/order/term', body: term)
    end

    def delete_order_term(request)
      _make_request('DELETE', '/order/term', body: request)
    end

    def update_order_term(request)
      _make_request('PATCH', '/order/term', body: request)
    end

    def get_order_term(term_reference_id)
      _make_request('GET', '/order/term', params: { term_reference_id: term_reference_id })
    end

    def refund_order_term(term)
      _make_request('POST', '/order/term/refund', body: term)
    end

    def terminate_order(request)
      _make_request('POST', '/order/terminate', body: request)
    end

    def manual_callback(request)
      _make_request('POST', '/order/callback', body: request)
    end

    def related_update(request)
      _make_request('PATCH', '/order/releated', body: request)
    end

    def add_basket_item(request)
      _make_request('POST', '/order/basket-item', body: request)
    end

    def remove_basket_item(request)
      _make_request('DELETE', '/order/basket-item', body: request)
    end

    def update_basket_item(request)
      _make_request('PATCH', '/order/basket-item', body: request)
    end

    # --- Organization Endpoints ---

    def get_organization_settings
      _make_request('GET', '/organization/settings')
    end

    def get_organization_callback
      _make_request('GET', '/organization/callback')
    end

    def update_organization_callback(request)
      _make_request('PATCH', '/organization/callback', body: request)
    end

    def create_organization_business(request)
      _make_request('POST', '/organization/business/create', body: request)
    end

    def get_organization_currencies
      _make_request('GET', '/organization/currencies')
    end

    def get_organization_limit_user(request)
      _make_request('GET', '/organization/limit/user', body: request)
    end

    def set_organization_limit_user(request)
      _make_request('POST', '/organization/limit/user', body: request)
    end

    def get_organization_limits
      _make_request('GET', '/organization/limits')
    end

    def list_organization_vpos(request)
      _make_request('POST', '/organization/list-vpos', body: request)
    end

    def get_organization_meta(name)
      # Backend route is /organization/metas/:name (plural)
      _make_request('GET', "/organization/metas/#{name}")
    end

    def get_organization_scopes
      _make_request('GET', '/organization/scopes')
    end

    def get_organization_suborganizations(params = {})
      _make_request('GET', '/organization/suborganizations', params: params)
    end

    def create_organization_user(request)
      _make_request('POST', '/organization/user/create', body: request)
    end

    def verify_organization_user(request)
      _make_request('POST', '/organization/user/verify', body: request)
    end

    def verify_organization_user_mobile(request)
      _make_request('POST', '/organization/user/verify-mobile', body: request)
    end

    def create_organization_user_token(request)
      _make_request('POST', '/organization/user/token', body: request)
    end

    def get_organization_suborganization(id)
      _make_request('GET', "/organization/suborganizations/#{id}")
    end

    # --- Subscription Endpoints ---

    def get_subscription(request)
      _make_request('POST', '/subscription', body: request)
    end

    def cancel_subscription(request)
      _make_request('POST', '/subscription/cancel', body: request)
    end

    def create_subscription(request)
      _make_request('POST', '/subscription/create', body: request)
    end

    def list_subscriptions(params = {})
      _make_request('GET', '/subscription/list', params: params)
    end

    def redirect_subscription(request)
      _make_request('POST', '/subscription/redirect', body: request)
    end

    # --- System Endpoints ---

    def get_system_order_statuses
      _make_request('GET', '/system/order-statuses')
    end

    def get_system_error_codes
      _make_request('GET', '/system/error-codes')
    end

    def get_system_transaction_purposes
      _make_request('GET', '/system/transaction-purposes')
    end

    def get_system_shortcut_types
      _make_request('GET', '/system/shortcut-types')
    end

    def get_system_payment_term_statuses
      _make_request('GET', '/system/payment-term-statuses')
    end

    def get_system_transaction_statuses
      _make_request('GET', '/system/transaction-statuses')
    end

    def get_system_product_types
      _make_request('GET', '/system/product-types')
    end

    def get_system_basket_item_types
      _make_request('GET', '/system/basket-item-types')
    end

    def get_system_transaction_payment_types
      _make_request('GET', '/system/transaction-payment-types')
    end

    def self.verify_webhook(payload, signature, secret)
      expected_signature = OpenSSL::HMAC.hexdigest('sha256', secret, payload)
      "sha256=#{expected_signature}" == signature
    end

    def get_health
      _make_request('GET', '/health')
    end

    private

    def handle_response(response)
      case response.code
      when 200..299
        response.parsed_response
      else
        error_data = response.parsed_response || {}
        api_code = error_data['code'] || -1
        error_msg = error_data['error'] || error_data['message'] || response.message
        raise APIException.new(response.code, api_code, error_msg)
      end
    end
  end

  class APIException < StandardError
    attr_reader :status_code, :api_code, :error_msg

    def initialize(status_code, api_code, error_msg)
      @status_code = status_code
      @api_code = api_code
      @error_msg = error_msg
      super("#{error_msg} (Status: #{status_code}, Code: #{api_code})")
    end
  end
end
