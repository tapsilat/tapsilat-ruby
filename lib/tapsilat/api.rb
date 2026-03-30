require 'httparty'
require 'json'
require 'openssl'

module Tapsilat
  class TapsilatAPI
    include HTTParty

    def initialize(api_key = '', timeout = 10, base_url = 'https://panel.tapsilat.dev/api/v1')
      @api_key = api_key
      @timeout = timeout
      @base_url = base_url.rstrip('/')
      
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
      raise Error, e.message
    end

    def create_order(order_data)
      # In Python it takes an OrderCreateDTO. In Ruby we might use a Hash or OpenStruct.
      # For now, let's assume it matches the payload.
      _make_request('POST', '/order/create', body: order_data)
      # Note: Python returns an OrderResponse object. Ruby might return a Hash or a wrapper.
    end

    def order_accounting(request)
      _make_request('POST', '/order/accounting', body: request)
    end

    def order_postauth(request)
      _make_request('POST', '/order/postauth', body: request)
    end

    def get_system_order_statuses
      _make_request('GET', '/system/order-statuses')
    end

    def get_order(reference_id)
      _make_request('GET', "/order/#{reference_id}")
    end

    def get_order_by_conversation_id(conversation_id)
      _make_request('GET', "/order/conversation/#{conversation_id}")
    end

    def get_order_list(page: 1, per_page: 10, start_date: '', end_date: '', organization_id: '', related_reference_id: '')
      params = {
        page: page,
        per_page: per_page,
        start_date: start_date,
        end_date: end_date,
        organization_id: organization_id,
        related_reference_id: related_reference_id
      }.reject { |_, v| v.nil? || v == '' }
      _make_request('GET', '/order/list', params: params)
    end

    def get_order_submerchants(page: 1, per_page: 10)
      params = { page: page, per_page: per_page }
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

    def get_orders(page: '1', per_page: '10', buyer_id: '')
      params = { page: page, per_page: per_page }
      params[:buyer_id] = buyer_id unless buyer_id.empty?
      _make_request('GET', '/order/list', params: params)
    end

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
      _make_request('GET', "/organization/meta/#{name}")
    end

    def get_organization_scopes
      _make_request('GET', '/organization/scopes')
    end

    def get_organization_suborganizations(page: 1, per_page: 10)
      params = { page: page, per_page: per_page }
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

    def get_subscription(request)
      _make_request('POST', '/subscription', body: request)
    end

    def cancel_subscription(request)
      _make_request('POST', '/subscription/cancel', body: request)
    end

    def create_subscription(request)
      _make_request('POST', '/subscription/create', body: request)
    end

    def list_subscriptions(page: 1, per_page: 10)
      params = { page: page, per_page: per_page }
      _make_request('GET', '/subscription/list', params: params)
    end

    def redirect_subscription(request)
      _make_request('POST', '/subscription/redirect', body: request)
    end

    def self.verify_webhook(payload, signature, secret)
      expected_signature = OpenSSL::HMAC.hexdigest('sha256', secret, payload)
      "sha256=#{expected_signature}" == signature
    end

    private

    def handle_response(response)
      case response.code
      when 200..299
        response.parsed_response
      else
        error_data = response.parsed_response || {}
        api_code = error_data['code'] || -1
        error_msg = error_data['error'] || response.message
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
