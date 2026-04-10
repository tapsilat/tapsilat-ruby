require 'httparty'
require_relative 'tapsilat/version'

module Tapsilat
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class APIException < Error
    attr_reader :status_code, :api_code, :error_msg

    def initialize(status_code, api_code, error_msg)
      @status_code = status_code
      @api_code = api_code
      @error_msg = error_msg
      super("HTTP #{status_code} [API #{api_code}]: #{error_msg}")
    end
  end

  # Legacy Error Aliases for compatibility with existing tests
  class OrderAPIError < Error; end
  class OrderValidationError < OrderAPIError; end
  class OrderNotFoundError < OrderAPIError; end
  class SubscriptionAPIError < Error; end

  class << self
    def base_url
      @base_url ||= ENV['TAPSILAT_BASE_URL'] || 'https://panel.tapsilat.dev/api/v1'
    end

    def base_url=(value)
      @base_url = value
    end

    def api_token
      @api_token ||= ENV['TAPSILAT_API_KEY'] || ENV['TAPSILAT_API_TOKEN']
    end

    def api_token=(value)
      @api_token = value
    end

    def configure
      yield self
    end

    def configured?
      !!(base_url && api_token)
    end

    def reset!
      @base_url = nil
      @api_token = nil
    end
  end
end

require_relative 'tapsilat/api'
require_relative 'tapsilat/models'
require_relative 'tapsilat/client'
