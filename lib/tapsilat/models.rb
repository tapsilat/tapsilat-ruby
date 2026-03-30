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

  class OrderCreateDTO < BaseDTO
    attr_accessor :amount, :currency, :locale, :buyer, :basket_items, :billing_address,
                  :checkout_design, :consents, :conversation_id, :enabled_installments,
                  :external_reference_id, :metadata, :order_cards, :paid_amount,
                  :partial_payment, :payment_failure_url, :payment_methods, :payment_mode,
                  :payment_options, :payment_success_url, :payment_terms, :pf_sub_merchant,
                  :redirect_failure_url, :redirect_success_url, :shipping_address,
                  :sub_organization, :submerchants, :tax_amount, :three_d_force

    def initialize(amount:, currency:, locale:, buyer:, **args)
      @amount = amount
      @currency = currency
      @locale = locale
      @buyer = buyer
      super(**args)
    end
  end

  class BuyerDTO < BaseDTO
    attr_accessor :name, :surname, :birth_date, :city, :country, :email, :gsm_number,
                  :id, :identity_number, :ip, :last_login_date, :registration_date,
                  :title, :zip_code

    def initialize(name:, surname:, **args)
      @name = name
      @surname = surname
      super(**args)
    end
  end

  class BasketItemDTO < BaseDTO
    attr_accessor :category1, :category2, :coupon, :coupon_discount, :data, :id,
                  :item_type, :name, :paid_amount, :price, :quantity
  end

  class AddressDTO < BaseDTO
    attr_accessor :address, :city, :country, :contact_name, :zip_code, :vat_number, :billing_type
  end

  class SubscriptionCreateRequest < BaseDTO
    attr_accessor :amount, :currency, :cycle, :period, :title, :user, :billing,
                  :external_reference_id, :payment_date, :price_option, :success_url, :failure_url

    def initialize(amount:, currency:, cycle:, period:, title:, user:, **args)
      @amount = amount
      @currency = currency
      @cycle = cycle
      @period = period
      @title = title
      @user = user
      super(**args)
    end
  end

  class SubscriptionPriceOption < BaseDTO
    attr_accessor :count, :price
  end

  class SubscriptionUserDTO < BaseDTO
    attr_accessor :address, :city, :country, :email, :first_name, :identity_number,
                  :id, :last_name, :phone, :zip_code
  end

  class PaymentTermCreateDTO < BaseDTO
    attr_accessor :amount, :due_date, :order_id, :required, :status,
                  :term_reference_id, :term_sequence
  end

  class PaymentTermUpdateDTO < BaseDTO
    attr_accessor :amount, :due_date, :required, :status,
                  :term_reference_id, :term_sequence
  end

  class OrderConsent < BaseDTO
    attr_accessor :title, :url
  end

  class CheckoutDesignDTO < BaseDTO
    attr_accessor :button_color, :button_text_color, :header_color, :header_text_color,
                  :logo_url, :primary_color, :primary_text_color, :selected_card_color
  end
end
