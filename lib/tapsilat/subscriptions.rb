module Tapsilat
  class Subscriptions
    def initialize(client)
      @client = client
    end

    def get(params = {})
      @client.post('/subscription', body: params.to_json)
    end

    def cancel(params = {})
      @client.post('/subscription/cancel', body: params.to_json)
    end

    def create(params = {})
      @client.post('/subscription/create', body: params.to_json)
    end

    def list(page: 1, per_page: 10)
      @client.get('/subscription/list', query: { page: page, per_page: per_page })
    end

    def redirect(params = {})
      @client.post('/subscription/redirect', body: params.to_json)
    end
  end
end
