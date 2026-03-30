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
        OrderResponse.new(response)
      end

      def get(reference_id)
        response = @api.get_order(reference_id)
        OrderResponse.new(response)
      end

      def list(params = {})
        @api.get_order_list(**params)
      end

      def get_status(reference_id)
        @api.get_order_status(reference_id)
      end

      def cancel(reference_id)
        @api.cancel_order({ reference_id: reference_id })
      end

      def refund(reference_id, amount, **args)
        payload = { reference_id: reference_id, amount: amount }.merge(args)
        @api.refund_order(payload)
      end
    end

    class Subscription < Base
      def create(params)
        @api.create_subscription(params)
      end

      def get(id)
        @api.get_subscription({ reference_id: id })
      end

      def list(params = {})
        @api.list_subscriptions(**params)
      end

      def cancel(reference_id:)
        @api.cancel_subscription({ reference_id: reference_id })
      end
    end

    class Organization < Base
      def settings
        @api.get_organization_settings
      end
    end
  end

  class OrderResponse
    def initialize(data)
      @data = data || {}
    end

    def reference_id
      @data['reference_id']
    end

    def checkout_url
      @data['checkout_url']
    end

    def order_id
      @data['order_id']
    end

    def to_h
      @data
    end
  end
end
