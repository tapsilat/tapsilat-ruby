require 'simplecov'
if ENV['COVERAGE']
  SimpleCov.start do
    add_filter '/spec/'
    minimum_coverage 80
  end
end

require 'bundler/setup'
require 'tapsilat'
require 'rspec'

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

  # Helper method to configure Tapsilat for tests with real API
  config.before(:each, :configured) do
    Tapsilat.configure do |config|
      config.base_url = 'https://panel.tapsilat.dev/api/v1'
      config.api_token = ENV['TAPSILAT_API_TOKEN'] || 'your-real-api-token-here'
    end
  end

  # All tests run against live API
  # Ensure API token is available for all tests
  config.before(:suite) do
    if ENV['TAPSILAT_API_TOKEN'].nil?
      puts 'Warning: TAPSILAT_API_TOKEN not set. Tests may fail without proper API credentials.'
    end
  end
end
