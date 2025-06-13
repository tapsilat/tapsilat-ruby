require 'simplecov'
if ENV['COVERAGE']
  SimpleCov.start do
    add_filter '/spec/'
    minimum_coverage 80
  end
end

require 'bundler/setup'
require 'tapsilat'
require 'webmock/rspec'
require 'vcr'

# Disable external HTTP requests
WebMock.disable_net_connect!(allow_localhost: true)

# VCR configuration
VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :once,
    match_requests_on: %i[method uri body]
  }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset Tapsilat configuration before each test
  config.before do
    Tapsilat.reset!
  end

  # Helper method to configure Tapsilat for tests
  config.before(:each, :configured) do
    Tapsilat.configure do |config|
      config.base_url = 'https://api.tapsilat.com'
      config.api_token = 'test-token'
    end
  end
end
