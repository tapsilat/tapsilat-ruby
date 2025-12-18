module Tapsilat
  class Health
    def initialize(client)
      @client = client
    end

    def check
      @client.get('/health')
    end
  end
end
