require 'httparty'
require_relative 'tapsilat/version'

module Tapsilat
  class Error < StandardError; end
  class ConfigurationError < Error; end

  class << self
    attr_accessor :base_url, :api_token

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

require_relative 'tapsilat/client'
require_relative 'tapsilat/orders'
