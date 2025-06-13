module Tapsilat
  # Order-specific error classes
  class OrderError < Error; end
  class OrderValidationError < OrderError; end
  class OrderCreationError < OrderError; end
  class OrderNotFoundError < OrderError; end
  class OrderAPIError < OrderError; end

  class Orders
    # Order status constants based on the API documentation
    ORDER_STATUS = {
      1 => 'Received',
      2 => 'Unpaid',
      3 => 'Paid',
      4 => 'Processing',
      5 => 'Shipped',
      6 => 'On hold',
      7 => 'Waiting for payment',
      8 => 'Cancelled',
      9 => 'Completed',
      10 => 'Refunded',
      11 => 'Fraud',
      12 => 'Rejected',
      13 => 'Failure',
      14 => 'Retrying',
      15 => 'Partially refunded',
      16 => 'Sub merchant payment approved',
      17 => 'Sub merchant payment disapproved',
      18 => 'Sub merchant payment errored',
      19 => 'Still has unpaid installments',
      20 => 'Still has unpaid terms',
      21 => 'Expired',
      22 => 'Still has unpaid sub merchant payments',
      23 => 'Partially Paid',
      24 => 'Terminated'
    }.freeze

    # Retry configuration
    MAX_RETRIES = 3
    RETRY_DELAY = 1.0 # seconds
    RETRYABLE_ERRORS = [
      Net::TimeoutError,
      Net::OpenTimeout,
      Net::ReadTimeout,
      SocketError,
      Errno::ECONNRESET,
      Errno::ECONNREFUSED,
      HTTParty::Error
    ].freeze

    def initialize(client)
      @client = client
    end

    def create(order_data)
      with_retry do
        begin
          validated_data = validate_order_data(order_data)
          response = @client.post('/orders', body: validated_data.to_json)
          
          # Check if response indicates success
          if response && response['status'] != 'error'
            OrderResponse.new(response)
          else
            # Handle API errors returned in response
            error_message = response&.dig('message') || response&.dig('error_message') || 'Order creation failed'
            raise OrderCreationError, error_message
          end
        rescue JSON::GeneratorError => e
          raise OrderValidationError, "Invalid order data - JSON serialization failed: #{e.message}"
        rescue ArgumentError => e
          raise OrderValidationError, e.message
        rescue Tapsilat::Error => e
          # Re-raise API errors with more context
          case e.message
          when /Unauthorized/
            raise OrderAPIError, "Order creation failed - Invalid API credentials: #{e.message}"
          when /Resource not found/
            raise OrderAPIError, "Order creation failed - Invalid endpoint: #{e.message}"
          when /Server error/
            raise OrderAPIError, "Order creation failed - Server error: #{e.message}"
          else
            raise OrderCreationError, "Order creation failed: #{e.message}"
          end
        rescue StandardError => e
          # Catch any other unexpected errors
          raise OrderError, "Unexpected error during order creation: #{e.message}"
        end
      end
    end

    def get(order_id)
      with_retry do
        begin
          raise ArgumentError, "Order ID cannot be nil or empty" if order_id.nil? || order_id.to_s.strip.empty?
          
          response = @client.get("/orders/#{order_id}")
          OrderResponse.new(response) if response
        rescue Tapsilat::Error => e
          case e.message
          when /Resource not found/
            raise OrderNotFoundError, "Order with ID '#{order_id}' not found"
          when /Unauthorized/
            raise OrderAPIError, "Failed to fetch order - Invalid API credentials: #{e.message}"
          else
            raise OrderAPIError, "Failed to fetch order: #{e.message}"
          end
        rescue StandardError => e
          raise OrderError, "Unexpected error while fetching order: #{e.message}"
        end
      end
    end

    def list(params = {})
      with_retry do
        begin
          # Build query parameters with defaults
          query_params = build_list_params(params)
          response = @client.get('/orders/list', query: query_params)
          OrderListResponse.new(response) if response
        rescue Tapsilat::Error => e
          case e.message
          when /Unauthorized/
            raise OrderAPIError, "Failed to list orders - Invalid API credentials: #{e.message}"
          else
            raise OrderAPIError, "Failed to list orders: #{e.message}"
          end
        rescue StandardError => e
          raise OrderError, "Unexpected error while listing orders: #{e.message}"
        end
      end
    end

    # Helper method to get status text from status code
    def self.status_text(status_code)
      ORDER_STATUS[status_code] || 'Unknown'
    end

    # Helper method to build order data structure
    def build_order(
      locale:,
      amount:,
      currency:,
      buyer:,
      billing_address:,
      basket_items:,
      payment_success_url: nil,
      payment_failure_url: nil,
      **options
    )
      {
        locale: locale,
        amount: amount.to_f,
        paid_amount: options[:paid_amount]&.to_f || 0.0,
        tax_amount: options[:tax_amount]&.to_f || 0.0,
        currency: currency,
        three_d_force: options[:three_d_force] || false,
        enabled_installments: options[:enabled_installments] || [1],
        external_reference_id: options[:external_reference_id],
        conversation_id: options[:conversation_id],
        buyer: build_buyer(buyer),
        shipping_address: options[:shipping_address] ? build_shipping_address(options[:shipping_address]) : nil,
        billing_address: build_billing_address(billing_address),
        basket_items: basket_items.map { |item| build_basket_item(item) },
        submerchants: options[:submerchants] || [],
        payment_terms: options[:payment_terms] || [],
        payment_methods: options[:payment_methods] || true,
        payment_failure_url: payment_failure_url,
        payment_success_url: payment_success_url,
        order_vpos_id: options[:order_vpos_id],
        order_cards: options[:order_cards] || [],
        partial_payment: options[:partial_payment] || false,
        pf_sub_merchant: options[:pf_sub_merchant] ? build_pf_sub_merchant(options[:pf_sub_merchant]) : nil,
        metadata: options[:metadata] || [],
        payment_options: options[:payment_options] || ['credit_card']
      }.compact
    end

    private

    def build_list_params(params)
      {
        page: params[:page] || 1,
        per_page: params[:per_page] || 10,
        start_date: params[:start_date],
        end_date: params[:end_date],
        organization_id: params[:organization_id],
        related_reference_id: params[:related_reference_id]
      }.compact
    end

    def validate_order_data(data)
      required_fields = %i[locale amount currency buyer billing_address basket_items]

      required_fields.each do |field|
        raise ArgumentError, "Missing required field: #{field}" unless data[field]
      end

      # Additional validations
      validate_amount(data[:amount])
      validate_currency(data[:currency])
      validate_buyer_data(data[:buyer])
      validate_basket_items(data[:basket_items])

      data
    end

    def validate_amount(amount)
      raise ArgumentError, "Amount must be a positive number" unless amount.is_a?(Numeric) && amount > 0
    end

    def validate_currency(currency)
      valid_currencies = %w[TRY USD EUR GBP]
      raise ArgumentError, "Invalid currency. Must be one of: #{valid_currencies.join(', ')}" unless valid_currencies.include?(currency.to_s.upcase)
    end

    def validate_buyer_data(buyer)
      required_buyer_fields = %i[name surname email]
      required_buyer_fields.each do |field|
        raise ArgumentError, "Missing required buyer field: #{field}" unless buyer[field]
      end
      
      # Basic email validation
      email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\z/i
      raise ArgumentError, "Invalid email format" unless buyer[:email].match?(email_regex)
    end

    def validate_basket_items(basket_items)
      raise ArgumentError, "Basket items cannot be empty" if basket_items.empty?
      
      basket_items.each_with_index do |item, index|
        raise ArgumentError, "Basket item #{index + 1}: missing required field 'id'" unless item[:id]
        raise ArgumentError, "Basket item #{index + 1}: missing required field 'name'" unless item[:name]
        raise ArgumentError, "Basket item #{index + 1}: missing required field 'price'" unless item[:price]
        raise ArgumentError, "Basket item #{index + 1}: missing required field 'quantity'" unless item[:quantity]
        raise ArgumentError, "Basket item #{index + 1}: price must be a positive number" unless item[:price].is_a?(Numeric) && item[:price] > 0
        raise ArgumentError, "Basket item #{index + 1}: quantity must be a positive integer" unless item[:quantity].is_a?(Integer) && item[:quantity] > 0
      end
    end

    def build_buyer(buyer_data)
      {
        id: buyer_data[:id],
        name: buyer_data[:name],
        surname: buyer_data[:surname],
        email: buyer_data[:email],
        gsm_number: buyer_data[:gsm_number],
        identity_number: buyer_data[:identity_number],
        registration_date: buyer_data[:registration_date],
        registration_address: buyer_data[:registration_address],
        last_login_date: buyer_data[:last_login_date],
        city: buyer_data[:city],
        country: buyer_data[:country],
        zip_code: buyer_data[:zip_code],
        ip: buyer_data[:ip],
        birth_date: buyer_data[:birth_date],
        title: buyer_data[:title]
      }.compact
    end

    def build_shipping_address(shipping_data)
      {
        address: shipping_data[:address],
        zip_code: shipping_data[:zip_code],
        city: shipping_data[:city],
        country: shipping_data[:country],
        contact_name: shipping_data[:contact_name],
        tracking_code: shipping_data[:tracking_code],
        shipping_date: shipping_data[:shipping_date]
      }.compact
    end

    def build_billing_address(billing_data)
      {
        billing_type: billing_data[:billing_type] || 'PERSONAL',
        citizenship: billing_data[:citizenship],
        vat_number: billing_data[:vat_number],
        city: billing_data[:city],
        district: billing_data[:district],
        country: billing_data[:country],
        address: billing_data[:address],
        zip_code: billing_data[:zip_code],
        contact_name: billing_data[:contact_name],
        contact_phone: billing_data[:contact_phone],
        title: billing_data[:title],
        tax_office: billing_data[:tax_office]
      }.compact
    end

    def build_basket_item(item_data)
      {
        id: item_data[:id],
        price: item_data[:price].to_f,
        quantity: item_data[:quantity].to_i,
        name: item_data[:name],
        category1: item_data[:category1],
        category2: item_data[:category2],
        item_type: item_data[:item_type] || 'PHYSICAL',
        sub_merchant_key: item_data[:sub_merchant_key],
        sub_merchant_price: item_data[:sub_merchant_price],
        coupon: item_data[:coupon],
        coupon_discount: item_data[:coupon_discount]&.to_f || 0.0,
        quantity_float: item_data[:quantity_float]&.to_f || item_data[:quantity].to_f,
        quantity_unit: item_data[:quantity_unit] || 'unit',
        paid_amount: item_data[:paid_amount]&.to_f || 0.0,
        data: item_data[:data],
        payer: item_data[:payer] ? build_payer(item_data[:payer]) : nil,
        commission_amount: item_data[:commission_amount]&.to_f || 0.0
      }.compact
    end

    def build_payer(payer_data)
      {
        type: payer_data[:type] || 'PERSONAL',
        title: payer_data[:title],
        address: payer_data[:address],
        vat: payer_data[:vat],
        tax_office: payer_data[:tax_office],
        reference_id: payer_data[:reference_id]
      }.compact
    end

    def build_pf_sub_merchant(sub_merchant_data)
      {
        id: sub_merchant_data[:id],
        name: sub_merchant_data[:name],
        postal_code: sub_merchant_data[:postal_code],
        city: sub_merchant_data[:city],
        country: sub_merchant_data[:country],
        mcc: sub_merchant_data[:mcc],
        terminal_no: sub_merchant_data[:terminal_no],
        org_id: sub_merchant_data[:org_id],
        country_iso_code: sub_merchant_data[:country_iso_code],
        address: sub_merchant_data[:address],
        submerchant_url: sub_merchant_data[:submerchant_url],
        submerchant_nin: sub_merchant_data[:submerchant_nin]
      }.compact
    end

    # Retry mechanism for transient network errors
    def with_retry(max_attempts: MAX_RETRIES, delay: RETRY_DELAY)
      attempts = 0
      
      begin
        attempts += 1
        yield
      rescue *RETRYABLE_ERRORS => e
        if attempts < max_attempts
          sleep(delay * attempts) # Exponential backoff
          retry
        else
          raise OrderError, "Max retry attempts (#{max_attempts}) exceeded. Last error: #{e.message}"
        end
      end
    end
  end

  # Order response wrapper class to handle API response data
  class OrderResponse
    attr_reader :data

    def initialize(response_data)
      @data = case response_data
              when String
                begin
                  JSON.parse(response_data)
                rescue JSON::ParserError => e
                  raise OrderError, "Invalid JSON response: #{e.message}"
                end
              when Hash
                response_data
              else
                raise OrderError, "Invalid response data type: #{response_data.class}"
              end
    end

    def locale
      @data['locale']
    end

    def reference_id
      @data['reference_id']
    end

    def external_reference_id
      @data['external_reference_id']
    end

    def amount
      @data['amount']&.to_f
    end

    def total
      @data['total']&.to_f
    end

    def paid_amount
      @data['paid_amount']&.to_f
    end

    def refunded_amount
      @data['refunded_amount']&.to_f
    end

    def created_at
      @data['created_at']
    end

    def currency
      @data['currency']
    end

    def status
      @data['status']&.to_i
    end

    def status_text
      Orders::ORDER_STATUS[status] || 'Unknown'
    end

    def status_enum
      @data['status_enum']
    end

    def buyer
      @data['buyer']
    end

    def shipping_address
      @data['shipping_address']
    end

    def billing_address
      @data['billing_address']
    end

    def basket_items
      @data['basket_items'] || []
    end

    def checkout_design
      @data['checkout_design']
    end

    def payment_terms
      @data['payment_terms'] || []
    end

    def payment_failure_url
      @data['payment_failure_url']
    end

    def payment_success_url
      @data['payment_success_url']
    end

    def checkout_url
      @data['checkout_url']
    end

    def conversation_id
      @data['conversation_id']
    end

    def payment_options
      @data['payment_options'] || []
    end

    def metadata
      @data['metadata'] || []
    end

    # Helper methods for common checks
    def paid?
      status == 3
    end

    def cancelled?
      status == 8
    end

    def completed?
      status == 9
    end

    def refunded?
      [10, 15].include?(status)
    end

    def pending_payment?
      [2, 7].include?(status)
    end

    def failed?
      [11, 12, 13].include?(status)
    end

    # Get total refundable amount from basket items
    def total_refundable_amount
      basket_items.sum { |item| item['refundable_amount']&.to_f || 0.0 }
    end

    # Get total paid amount from basket items
    def total_paid_amount_from_items
      basket_items.sum { |item| item['paid_amount']&.to_f || 0.0 }
    end

    def to_h
      @data
    end

    def to_json(*args)
      @data.to_json(*args)
    end
  end

  # Order list response wrapper class to handle paginated API response
  class OrderListResponse
    attr_reader :data

    def initialize(response_data)
      @data = case response_data
              when String
                begin
                  JSON.parse(response_data)
                rescue JSON::ParserError => e
                  raise OrderError, "Invalid JSON response: #{e.message}"
                end
              when Hash
                response_data
              else
                raise OrderError, "Invalid response data type: #{response_data.class}"
              end
    end

    def rows
      (@data['rows'] || []).map { |order_data| OrderResponse.new(order_data) }
    end

    def total
      @data['total']&.to_i || 0
    end

    def page
      @data['page']&.to_i || 1
    end

    def per_page
      @data['per_page']&.to_i || 10
    end

    def total_pages
      @data['total_pages']&.to_i || 0
    end

    # Helper methods for pagination
    def first_page?
      page == 1
    end

    def last_page?
      page >= total_pages
    end

    def has_next_page?
      page < total_pages
    end

    def has_previous_page?
      page > 1
    end

    def next_page
      has_next_page? ? page + 1 : nil
    end

    def previous_page
      has_previous_page? ? page - 1 : nil
    end

    # Get orders with specific status
    def orders_with_status(status_code)
      rows.select { |order| order.status == status_code }
    end

    # Get paid orders
    def paid_orders
      rows.select(&:paid?)
    end

    # Get pending orders
    def pending_orders
      rows.select(&:pending_payment?)
    end

    # Get cancelled orders
    def cancelled_orders
      rows.select(&:cancelled?)
    end

    # Get total amount of all orders in the list
    def total_amount
      rows.sum(&:amount)
    end

    # Get total paid amount of all orders in the list
    def total_paid_amount
      rows.sum(&:paid_amount)
    end

    def empty?
      rows.empty?
    end

    def count
      rows.length
    end

    def to_h
      @data
    end

    def to_json(*args)
      @data.to_json(*args)
    end
  end
end
