module Tapsilat
  class Organization
    def initialize(client)
      @client = client
    end

    def settings
      @client.get('/organization/settings')
    end
  end
end
