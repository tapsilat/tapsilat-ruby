require_relative 'api'
require_relative 'models'

module Tapsilat
  class Client
    def initialize(api_key = Tapsilat.api_token, timeout = 10, base_url = Tapsilat.base_url)
      @api = TapsilatAPI.new(api_key, timeout, base_url)
    end

    def orders
      @orders ||= Resource::Order.new(@api)
    end

    def subscriptions
      @subscriptions ||= Resource::Subscription.new(@api)
    end

    def organization
      @organization ||= Resource::Organization.new(@api)
    end

    def system
      @system ||= Resource::System.new(@api)
    end

    def health
      @health ||= Resource::Health.new(@api)
    end
  end

  module Resource
    class Base
      def initialize(api)
        @api = api
      end
    end

    class Order < Base
      def build_order(params)
        OrderCreateDTO.new(**params)
      end

      def create(order_dto)
        payload = order_dto.respond_to?(:to_h) ? order_dto.to_h : order_dto
        response = @api.create_order(payload)
        TapsilatOrderCreateResponse.new(response.transform_keys(&:to_sym))
      end

      def get(reference_id)
        response = @api.get_order(reference_id)
        OrderResponse.new(response)
      end

      def list(
        page: 1, per_page: 10,
        start_date: nil, end_date: nil,
        organization_id: nil, related_reference_id: nil,
        buyer_id: nil, **extra
      )
        response = @api.get_order_list(
          page: page, per_page: per_page,
          start_date: start_date, end_date: end_date,
          organization_id: organization_id,
          related_reference_id: related_reference_id,
          buyer_id: buyer_id,
          **extra
        )
        OrderListResponse.new(response)
      end

      def get_status(reference_id)
        @api.get_order_status(reference_id)
      end

      def cancel(reference_id)
        @api.cancel_order({ reference_id: reference_id })
      end

      def refund(reference_id, amount, order_item_id: nil, order_item_payment_id: nil, **args)
        payload = { reference_id: reference_id, amount: amount }
        payload[:order_item_id]         = order_item_id         if order_item_id
        payload[:order_item_payment_id] = order_item_payment_id if order_item_payment_id
        payload.merge!(args)
        @api.refund_order(payload)
      end
    end

    class Subscription < Base
      def create(subscription_dto)
        payload = subscription_dto.respond_to?(:to_h) ? subscription_dto.to_h : subscription_dto
        response = @api.create_subscription(payload)
        SubscriptionCreateResponse.new(response.transform_keys(&:to_sym))
      end

      def get(reference_id: nil, external_reference_id: nil)
        payload = {}
        payload[:reference_id]          = reference_id          if reference_id
        payload[:external_reference_id] = external_reference_id if external_reference_id
        @api.get_subscription(payload)
      end

      def list(page: 1, per_page: 10)
        @api.list_subscriptions(page: page, per_page: per_page)
      end

      def cancel(reference_id: nil, external_reference_id: nil)
        payload = {}
        payload[:reference_id]          = reference_id          if reference_id
        payload[:external_reference_id] = external_reference_id if external_reference_id
        @api.cancel_subscription(payload)
      end

      def redirect(subscription_id)
        @api.redirect_subscription({ subscription_id: subscription_id })
      end
    end

    class Organization < Base
      def settings
        @api.get_organization_settings
      end

      def get_suborganization(id)
        @api.get_organization_suborganization(id)
      end

      def create_user_token(request)
        @api.create_organization_user_token(request)
      end
    end

    class System < Base
      def error_codes
        @api.get_system_error_codes
      end

      def transaction_purposes
        @api.get_system_transaction_purposes
      end

      def shortcut_types
        @api.get_system_shortcut_types
      end

      def order_statuses
        @api.get_system_order_statuses
      end

      def payment_term_statuses
        @api.get_system_payment_term_statuses
      end

      def transaction_statuses
        @api.get_system_transaction_statuses
      end

      def product_types
        @api.get_system_product_types
      end

      def basket_item_types
        @api.get_system_basket_item_types
      end

      def transaction_payment_types
        @api.get_system_transaction_payment_types
      end
    end

    class Health < Base
      def check
        @api.get_health
      end
    end
  end
end

