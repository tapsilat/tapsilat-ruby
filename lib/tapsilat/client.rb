module Tapsilat
  class Client
    include HTTParty

    def initialize
      raise ConfigurationError, 'Tapsilat not configured' unless Tapsilat.configured?

      self.class.base_uri Tapsilat.base_url
      self.class.headers(
        'Authorization' => "Bearer #{Tapsilat.api_token}",
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      )
    end

    def orders
      @orders ||= Orders.new(self)
    end

    def get(path, options = {})
      handle_response(self.class.get(path, options))
    end

    def post(path, options = {})
      handle_response(self.class.post(path, options))
    end

    def put(path, options = {})
      handle_response(self.class.put(path, options))
    end

    def delete(path, options = {})
      handle_response(self.class.delete(path, options))
    end

    private

    def handle_response(response)
      case response.code
      when 200..299
        response.parsed_response
      when 401
        raise Error, 'Unauthorized: Invalid API token'
      when 404
        raise Error, 'Resource not found'
      when 500
        raise Error, 'Server error'
      else
        raise Error, "Request failed with status #{response.code}"
      end
    end
  end
end
