require 'httparty'
require_relative 'tapsilat/version'

module Tapsilat
  class Error < StandardError; end
  class ConfigurationError < Error; end

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
