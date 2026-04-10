require 'json'

module Tapsilat
  class BaseDTO
    def initialize(**args)
      args.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
    end

    def to_h
      instance_variables.each_with_object({}) do |var, hash|
        val = instance_variable_get(var)
        next if val.nil?

        name = var.to_s.delete('@').to_sym
        hash[name] = format_value(val)
      end
    end

    def [](key)
      send(key) if respond_to?(key)
    end

    def fetch(key, default = nil)
      self[key] || default
    end

    def keys
      instance_variables.map { |v| v.to_s.delete('@').to_sym }
    end

    private

    def format_value(value)
      if value.is_a?(Array)
        value.map { |v| v.respond_to?(:to_h) ? v.to_h : v }
      elsif value.respond_to?(:to_h)
        value.to_h
      else
        value
      end
    end
  end

  class BaseResponse < BaseDTO
    attr_accessor :code, :message

    def success?
      code == 0 || code == 200
    end
  end

  # ---------------------------------------------------------------------------
  # Shared / Nested DTOs
  # ---------------------------------------------------------------------------

  class MetadataDTO < BaseDTO
    attr_accessor :key, :value
  end

  class OrderConsent < BaseDTO
    attr_accessor :title, :url
  end

  class OrderCardDTO < BaseDTO
    attr_accessor :card_id, :card_sequence, :is_default

    def initialize(card_id:, card_sequence:, **args)
      @card_id       = card_id
      @card_sequence = card_sequence
      super(**args)
    end
  end

  # ---------------------------------------------------------------------------
  # Buyer
  # ---------------------------------------------------------------------------

  class BuyerDTO < BaseDTO
    attr_accessor :name, :surname, :birth_date, :birdth_date, :city, :country, :email,
                  :gsm_number, :id, :identity_number, :ip, :last_login_date,
                  :registration_date, :title, :zip_code, :registration_address

    def initialize(name:, surname:, **args)
      @name    = name
      @surname = surname
      super(**args)
    end
  end

  # ---------------------------------------------------------------------------
  # Basket Item
  # ---------------------------------------------------------------------------

  class BasketItemPayerDTO < BaseDTO
    attr_accessor :address, :reference_id, :tax_office, :title, :type, :vat
  end

  class BasketItemDTO < BaseDTO
    attr_accessor :category1, :category2, :coupon, :coupon_discount, :data,
                  :id, :item_type, :name, :paid_amount, :price,
                  :commission_amount, :mcc, :payer, :quantity, :quantity_float,
                  :quantity_unit, :sub_merchant_key, :sub_merchant_price,
                  # response-only fields (present in proto / order detail response)
                  :status, :refunded_amount, :refundable_amount, :paidable_amount,
                  :item_payments
  end

  # ---------------------------------------------------------------------------
  # Addresses
  # ---------------------------------------------------------------------------

  class BillingAddressDTO < BaseDTO
    attr_accessor :address, :billing_type, :citizenship, :city, :contact_name,
                  :contact_phone, :country, :district, :tax_office, :title,
                  :vat_number, :zip_code, :neighbourhood, :street1, :street2,
                  :street3
  end

  # Kept as alias for backward-compat — same fields
  AddressDTO = BillingAddressDTO

  class ShippingAddressDTO < BaseDTO
    attr_accessor :address, :city, :contact_name, :country, :shipping_date,
                  :tracking_code, :zip_code
  end

  # ---------------------------------------------------------------------------
  # Checkout Design
  # ---------------------------------------------------------------------------

  class CheckoutDesignDTO < BaseDTO
    attr_accessor :input_background_color, :input_text_color, :label_text_color,
                  :left_background_color, :logo, :order_detail_html,
                  :right_background_color, :text_color, :pay_button_color,
                  :redirect_url
  end

  # ---------------------------------------------------------------------------
  # Sub-Organisation / Sub-Merchants / PF Sub-Merchant
  # ---------------------------------------------------------------------------

  class SubOrganizationDTO < BaseDTO
    attr_accessor :acquirer, :address, :contact_first_name, :contact_last_name,
                  :currency, :email, :gsm_number, :iban, :identity_number,
                  :legal_company_title, :organization_name,
                  :sub_merchant_external_id, :sub_merchant_key,
                  :sub_merchant_type, :tax_number, :tax_office
  end

  class SubmerchantDTO < BaseDTO
    attr_accessor :amount, :merchant_reference_id, :order_basket_item_id
  end

  class OrderPFSubMerchantDTO < BaseDTO
    attr_accessor :mcc, :name, :org_id, :address, :city, :country,
                  :country_iso_code, :id, :national_id, :postal_code,
                  :submerchant_nin, :submerchant_url, :switch_id, :terminal_no
  end

  # ---------------------------------------------------------------------------
  # Payment Terms (nested)
  # ---------------------------------------------------------------------------

  class PaymentTermDTO < BaseDTO
    attr_accessor :amount, :data, :due_date, :paid_date, :required, :status,
                  :term_reference_id, :term_sequence,
                  # additional fields present in proto / response
                  :id, :hash_id, :term_payments
  end

  # ---------------------------------------------------------------------------
  # Tokenized Payment
  # ---------------------------------------------------------------------------

  class TokenizedPaymentDTO < BaseDTO
    attr_accessor :card_token, :pos_id
  end

  # ---------------------------------------------------------------------------
  # Order Create Request
  # ---------------------------------------------------------------------------

  class OrderCreateDTO < BaseDTO
    attr_accessor :amount, :currency, :locale, :buyer,
                  :basket_items, :billing_address, :checkout_design, :consents,
                  :conversation_id, :enabled_installments, :external_reference_id,
                  :metadata, :order_cards, :paid_amount, :partial_payment,
                  :payment_failure_url, :payment_methods, :payment_mode,
                  :payment_options, :payment_success_url, :payment_terms,
                  :pf_sub_merchant, :redirect_failure_url, :redirect_success_url,
                  :shipping_address, :sub_organization, :sub_merchants, :tax_amount,
                  :three_d_force,
                  # additional fields
                  :basket_id, :payment_group, :callback_url, :tokenized_payment,
                  :order_type, :order_vpos_id, :fee, :related_reference_id,
                  :installment

    def initialize(amount:, currency:, locale:, buyer:, **args)
      @amount   = amount
      @currency = currency
      @locale   = locale
      @buyer    = buyer
      super(**args)
    end
  end

  # ---------------------------------------------------------------------------
  # Order Create Response
  # ---------------------------------------------------------------------------

  class TapsilatOrderCreateResponse < BaseResponse
    attr_accessor :id, :reference_id, :organization_id
  end

  # ---------------------------------------------------------------------------
  # Order Detail / Get Response
  # ---------------------------------------------------------------------------

  class OrderResponse < BaseResponse
    attr_accessor :id, :reference_id, :external_reference_id, :amount, :total,
                  :paid_amount, :refunded_amount, :created_at, :currency,
                  :status, :status_enum, :buyer, :shipping_address,
                  :billing_address, :basket_items, :checkout_design,
                  :payment_terms, :payment_failure_url, :payment_success_url,
                  :checkout_url, :conversation_id, :payment_options, :metadata,
                  :consents, :redirect_success_url, :redirect_failure_url,
                  :order_note, :order_card, :locale, :fee, :three_d_force

    def initialize(data = {})
      @data = data.is_a?(String) ? JSON.parse(data) : (data || {})
      @data = {} unless @data.is_a?(Hash)
      super(**@data.transform_keys(&:to_sym))
    end

    def status_text
      case status
      when 2  then 'Unpaid'
      when 3  then 'Paid'
      when 7  then 'Waiting for Payment'
      when 8  then 'Cancelled'
      when 9  then 'Completed'
      when 10 then 'Refunded'
      when 11 then 'Fraud'
      when 12 then 'Rejected'
      when 13 then 'Failure'
      when 15 then 'Partially Refunded'
      else         'Unknown'
      end
    end

    def paid?;            status == 3; end
    def cancelled?;       status == 8; end
    def completed?;       status == 9; end
    def refunded?;        [10, 15].include?(status); end
    def pending_payment?; [2, 7].include?(status); end
    def failed?;          [11, 12, 13].include?(status); end

    def total_refundable_amount
      return 0.0 unless basket_items.is_a?(Array)
      basket_items.sum { |item| (item['refundable_amount'] || 0.0).to_f }
    end

    def total_paid_amount_from_items
      return 0.0 unless basket_items.is_a?(Array)
      basket_items.sum { |item| (item['paid_amount'] || 0.0).to_f }
    end

    def to_h; @data; end
    def to_json(*args); @data.to_json(*args); end
  end

  # ---------------------------------------------------------------------------
  # Order List Response (Paginated)
  # ---------------------------------------------------------------------------

  class OrderListResponse < BaseResponse
    attr_accessor :rows, :total, :page, :per_page, :total_pages

    def initialize(data = {})
      @data = data.is_a?(String) ? JSON.parse(data) : (data || {})
      @data = {} unless @data.is_a?(Hash)
      super(**@data.transform_keys(&:to_sym))
      
      # Convert rows to OrderResponse objects
      @rows = (@data['rows'] || []).map { |r| OrderResponse.new(r) }
      @total = (@data['total'] || 0).to_i
      @page = (@data['page'] || 1).to_i
      @per_page = (@data['per_page'] || 10).to_i
      @total_pages = (@data['total_pages'] || 0).to_i
    end

    def first_page?; page == 1; end
    def last_page?; page >= total_pages; end
    def has_next_page?; page < total_pages; end
    def has_previous_page?; page > 1; end
    def next_page; has_next_page? ? page + 1 : nil; end
    def previous_page; has_previous_page? ? page - 1 : nil; end

    def orders_with_status(s); rows.select { |o| o.status == s }; end
    def paid_orders; rows.select(&:paid?); end
    def pending_orders; rows.select(&:pending_payment?); end
    def cancelled_orders; rows.select(&:cancelled?); end

    def total_amount; rows.sum { |o| (o.amount || 0.0).to_f }; end
    def total_paid_amount; rows.sum { |o| (o.paid_amount || 0.0).to_f }; end

    def empty?; rows.empty?; end
    def count; rows.size; end

    def to_h; @data; end
    def to_json(*args); @data.to_json(*args); end
  end

  # ---------------------------------------------------------------------------
  # Order Operations: Accounting / Post-Auth / Callback / Status
  # ---------------------------------------------------------------------------

  class OrderAccountingRequest < BaseDTO
    attr_accessor :order_reference_id

    def initialize(order_reference_id:)
      @order_reference_id = order_reference_id
    end
  end

  class OrderPostAuthRequest < BaseDTO
    attr_accessor :amount, :reference_id

    def initialize(amount:, reference_id:)
      @amount       = amount
      @reference_id = reference_id
    end
  end

  class OrderManualCallbackDTO < BaseDTO
    attr_accessor :reference_id, :conversation_id

    def initialize(reference_id:, **args)
      @reference_id = reference_id
      super(**args)
    end
  end

  class TerminateRequest < BaseDTO
    attr_accessor :reference_id

    def initialize(reference_id:)
      @reference_id = reference_id
    end
  end

  # ---------------------------------------------------------------------------
  # Order: Refund / Cancel
  # ---------------------------------------------------------------------------

  class RefundOrderDTO < BaseDTO
    attr_accessor :amount, :reference_id, :order_item_id, :order_item_payment_id

    def initialize(amount:, reference_id:, **args)
      @amount       = amount
      @reference_id = reference_id
      super(**args)
    end
  end

  class CancelOrderDTO < BaseDTO
    attr_accessor :reference_id

    def initialize(reference_id:)
      @reference_id = reference_id
    end
  end

  class RefundAllOrderDTO < BaseDTO
    attr_accessor :reference_id

    def initialize(reference_id:)
      @reference_id = reference_id
    end
  end

  # Kept for backward-compat
  OrderRefundRequest  = RefundOrderDTO
  OrderCancelRequest  = CancelOrderDTO

  # ---------------------------------------------------------------------------
  # Order: Payment Details
  # ---------------------------------------------------------------------------

  class OrderPaymentDetailDTO < BaseDTO
    attr_accessor :reference_id, :conversation_id

    def initialize(reference_id:, **args)
      @reference_id = reference_id
      super(**args)
    end
  end

  # ---------------------------------------------------------------------------
  # Order: Related Reference
  # ---------------------------------------------------------------------------

  class OrderRelatedReferenceDTO < BaseDTO
    attr_accessor :reference_id, :related_reference_id

    def initialize(reference_id:, related_reference_id:)
      @reference_id         = reference_id
      @related_reference_id = related_reference_id
    end
  end

  # ---------------------------------------------------------------------------
  # Order: Payment Terms CRUD
  # ---------------------------------------------------------------------------

  class OrderPaymentTermCreateDTO < BaseDTO
    attr_accessor :order_id, :term_reference_id, :amount, :due_date,
                  :term_sequence, :required, :status, :data, :paid_date

    def initialize(order_id:, term_reference_id:, amount:, due_date:,
                   term_sequence:, required:, status:, **args)
      @order_id          = order_id
      @term_reference_id = term_reference_id
      @amount            = amount
      @due_date          = due_date
      @term_sequence     = term_sequence
      @required          = required
      @status            = status
      super(**args)
    end
  end

  class OrderPaymentTermUpdateDTO < BaseDTO
    attr_accessor :term_reference_id, :term_sequence, :required, :amount,
                  :due_date, :paid_date, :status

    def initialize(term_reference_id:, term_sequence:, required:, amount:,
                   due_date:, status:, **args)
      @term_reference_id = term_reference_id
      @term_sequence     = term_sequence
      @required          = required
      @amount            = amount
      @due_date          = due_date
      @status            = status
      super(**args)
    end
  end

  class OrderPaymentTermDeleteDTO < BaseDTO
    attr_accessor :order_id, :term_reference_id

    def initialize(order_id:, term_reference_id:)
      @order_id          = order_id
      @term_reference_id = term_reference_id
    end
  end

  class OrderTermRefundRequest < BaseDTO
    attr_accessor :term_id, :amount, :reference_id, :term_payment_id

    def initialize(term_id:, amount:, **args)
      @term_id = term_id
      @amount  = amount
      super(**args)
    end
  end

  # ---------------------------------------------------------------------------
  # Order: Basket Item Operations
  # ---------------------------------------------------------------------------

  class AddBasketItemRequest < BaseDTO
    attr_accessor :order_reference_id, :basket_item

    def initialize(order_reference_id:, basket_item:)
      @order_reference_id = order_reference_id
      @basket_item        = basket_item
    end
  end

  class RemoveBasketItemRequest < BaseDTO
    attr_accessor :order_reference_id, :basket_item_id

    def initialize(order_reference_id:, basket_item_id:)
      @order_reference_id = order_reference_id
      @basket_item_id     = basket_item_id
    end
  end

  class UpdateBasketItemRequest < BaseDTO
    attr_accessor :order_reference_id, :basket_item

    def initialize(order_reference_id:, basket_item:)
      @order_reference_id = order_reference_id
      @basket_item        = basket_item
    end
  end

  # ---------------------------------------------------------------------------
  # System Response DTOs
  # ---------------------------------------------------------------------------

  class SystemStatusItem < BaseDTO
    attr_accessor :code, :message
  end

  class GetOrderStatusesRes < BaseDTO
    attr_accessor :statuses
  end

  class GetErrorCodesRes < BaseDTO
    attr_accessor :codes
  end

  class GetTxPurposesRes < BaseDTO
    attr_accessor :purposes
  end

  class GetShortcutTypesRes < BaseDTO
    attr_accessor :types
  end

  class GetPaymentTermStatusesRes < BaseDTO
    attr_accessor :statuses
  end

  class GetTransactionStatusesRes < BaseDTO
    attr_accessor :statuses
  end

  class GetProductTypesRes < BaseDTO
    attr_accessor :types
  end

  class GetBasketItemTypesRes < BaseDTO
    attr_accessor :types
  end

  class GetTransactionPaymentTypesRes < BaseDTO
    attr_accessor :types
  end

  # ---------------------------------------------------------------------------
  # Subscription
  # ---------------------------------------------------------------------------

  class SubscriptionBillingDTO < BaseDTO
    attr_accessor :address, :city, :contact_name, :country, :vat_number,
                  :zip_code
  end

  class SubscriptionUserDTO < BaseDTO
    attr_accessor :address, :city, :country, :email, :first_name, :id,
                  :identity_number, :last_name, :phone, :zip_code
  end

  class SubscriptionCreateRequest < BaseDTO
    attr_accessor :amount, :billing, :card_id, :currency, :cycle,
                  :external_reference_id, :failure_url, :payment_date,
                  :period, :success_url, :title, :user

    def initialize(amount:, currency:, cycle:, period:, title:, user:, **args)
      @amount   = amount
      @currency = currency
      @cycle    = cycle
      @period   = period
      @title    = title
      @user     = user
      super(**args)
    end
  end

  class SubscriptionGetRequest < BaseDTO
    attr_accessor :reference_id, :external_reference_id
  end

  class SubscriptionCancelRequest < BaseDTO
    attr_accessor :reference_id, :external_reference_id
  end

  class SubscriptionRedirectRequest < BaseDTO
    attr_accessor :subscription_id
  end

  class SubscriptionCreateResponse < BaseResponse
    attr_accessor :reference_id, :order_reference_id
  end

  # ---------------------------------------------------------------------------
  # Organisation
  # ---------------------------------------------------------------------------

  class CallbackURLDTO < BaseDTO
    attr_accessor :callback_url, :cancel_callback_url, :fail_callback_url,
                  :refund_callback_url
  end

  class OrgCreateBusinessRequest < BaseDTO
    # business_type: 0 = INDIVIDUAL, 1 = CORPORATE
    INDIVIDUAL = 0
    CORPORATE  = 1

    attr_accessor :address, :business_name, :business_type, :email,
                  :first_name, :identity_number, :last_name, :phone,
                  :tax_number, :tax_office, :zip_code

    def initialize(address:, business_name:, business_type:, email:,
                   first_name:, identity_number:, last_name:, phone:,
                   tax_number:, tax_office:, zip_code:)
      @address         = address
      @business_name   = business_name
      @business_type   = business_type
      @email           = email
      @first_name      = first_name
      @identity_number = identity_number
      @last_name       = last_name
      @phone           = phone
      @tax_number      = tax_number
      @tax_office      = tax_office
      @zip_code        = zip_code
    end
  end

  class GetUserLimitRequest < BaseDTO
    attr_accessor :user_id

    def initialize(user_id:)
      @user_id = user_id
    end
  end

  class SetLimitUserRequest < BaseDTO
    attr_accessor :limit_id, :user_id

    def initialize(limit_id:, user_id:)
      @limit_id = limit_id
      @user_id  = user_id
    end
  end

  class GetVposRequest < BaseDTO
    attr_accessor :currency_id

    def initialize(currency_id:)
      @currency_id = currency_id
    end
  end

  class OrgCreateUserReq < BaseDTO
    attr_accessor :conversation_id, :email, :first_name, :identity_number,
                  :is_mail_verified, :last_name, :phone, :reference_id

    def initialize(conversation_id:, email:, first_name:, identity_number:,
                   is_mail_verified:, last_name:, phone:, reference_id:)
      @conversation_id  = conversation_id
      @email            = email
      @first_name       = first_name
      @identity_number  = identity_number
      @is_mail_verified = is_mail_verified
      @last_name        = last_name
      @phone            = phone
      @reference_id     = reference_id
    end
  end

  class OrgUserVerifyReq < BaseDTO
    attr_accessor :user_id

    def initialize(user_id:)
      @user_id = user_id
    end
  end

  class OrgUserTokenReq < BaseDTO
    attr_accessor :email, :expire, :invalidate_old_tokens
  end

  class OrgWaasProviderListReq < BaseDTO
    attr_accessor :page, :per_page
  end

  class GetSubOrganizationRequest < BaseDTO
    attr_accessor :id
  end

  class OrgUserMobileVerifyReq < BaseDTO
    attr_accessor :user_id

    def initialize(user_id:)
      @user_id = user_id
    end
  end
end
