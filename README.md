# Tapsilat Ruby Client [![Gem Version](https://badge.fury.io/rb/tapsilat.svg?icon_color=%23ff0002)](https://badge.fury.io/rb/tapsilat)

A Ruby client for the Tapsilat API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tapsilat'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install tapsilat

## Usage

Configure the client with your API credentials:

```ruby
Tapsilat.configure do |config|
  config.base_url = ENV['TAPSILAT_BASE_URL']
  config.api_token = ENV['TAPSILAT_API_TOKEN']
end
```

Create a client instance and start using the API:

```ruby
client = Tapsilat::Client.new

# Create an order
order_data = client.orders.build_order(
  locale: "tr",
  amount: 100.0,
  currency: "TRY",
  buyer: {
    name: "John",
    surname: "Doe",
    email: "john@doe.com"
  },
  billing_address: {
    billing_type: "PERSONAL",
    city: "Istanbul",
    country: "TR"
  },
  basket_items: [
    {
      id: "BI101",
      price: 100.0,
      quantity: 1,
      name: "Test Product"
    }
  ]
)

response = client.orders.create(order_data)

# Get an order
order = client.orders.get(order_id)
puts order.status_text

# List orders
orders = client.orders.list(page: 1, per_page: 10)
orders.rows.each do |order|
  puts "#{order.reference_id}: #{order.status_text}"
end

# Get order status
status = client.orders.get_status(order_id)
puts status.status
```

### Subscriptions

```ruby
# Create a subscription
subscription = client.subscriptions.create(
  title: 'Monthly Plan',
  amount: 99.99,
  currency: 'TRY',
  period: 30,
  user: {
    first_name: 'John',
    last_name: 'Doe',
    email: 'john@example.com'
  }
)

# Get subscription details
details = client.subscriptions.get(reference_id: subscription['reference_id'])

# List subscriptions
subscriptions = client.subscriptions.list(page: 1, per_page: 10)

# Cancel a subscription
client.subscriptions.cancel(reference_id: subscription['reference_id'])

# Get redirect URL
redirect = client.subscriptions.redirect(subscription_id: subscription['reference_id'])
puts redirect['url']
```

### Organization Settings

```ruby
# Get organization settings
settings = client.organization.settings
puts "Organization: #{settings['organization_name']}"
puts "Currency: #{settings['currency']}"
```

### Health Check

```ruby
# Check API health
health = client.health.check
puts "API Status: #{health['status']}"
```


## Error Handling

The client provides comprehensive error handling with specific exception types:

```ruby
begin
  # Create an order
  order = client.orders.create(order_data)
  puts "Order created successfully: #{order.reference_id}"
rescue Tapsilat::OrderValidationError => e
  puts "Validation error: #{e.message}"
  # Handle validation errors (missing fields, invalid data, etc.)
rescue Tapsilat::OrderCreationError => e
  puts "Order creation failed: #{e.message}"
  # Handle order creation failures
rescue Tapsilat::OrderAPIError => e
  puts "API error: #{e.message}"
  # Handle API-related errors (auth, server errors, etc.)
rescue Tapsilat::OrderError => e
  puts "General order error: #{e.message}"
  # Handle any other order-related errors
end

# Specific error handling for different operations
begin
  order = client.orders.get(order_id)
rescue Tapsilat::OrderNotFoundError => e
  puts "Order not found: #{e.message}"
rescue Tapsilat::OrderAPIError => e
  puts "API error while fetching order: #{e.message}"
end
```

### Error Types

- `Tapsilat::OrderError` - Base class for all order-related errors
- `Tapsilat::OrderValidationError` - Validation errors (missing/invalid data)
- `Tapsilat::OrderCreationError` - Order creation failures
- `Tapsilat::OrderNotFoundError` - Order not found errors
- `Tapsilat::OrderAPIError` - API-related errors (auth, server, etc.)

### Retry Mechanism

The client automatically retries transient network errors (timeouts, connection issues) up to 3 times with exponential backoff. This helps handle temporary network issues gracefully.

## Features

- **Orders**: Full order lifecycle management
  - Order creation with comprehensive validation
  - Order retrieval and status tracking
  - Order listing with pagination
  - Order status queries
- **Subscriptions**: Complete subscription management
  - Create recurring subscriptions
  - Get subscription details
  - List subscriptions with pagination
  - Cancel subscriptions
  - Get redirect URLs for subscription payments
- **Organization**: Organization settings and configuration
  - Fetch organization settings
  - Get merchant configuration
- **Health Check**: API health monitoring
  - Verify API availability and status
- **Error Handling**: Built-in validation and comprehensive error types
- **Retry Mechanism**: Automatic retry for transient network errors
- **Response Models**: Convenient wrapper objects with helper methods
- **Pagination Support**: Easy pagination for list endpoints
- **Full Test Coverage**: Comprehensive RSpec test suite with WebMock

## Testing

Run the test suite:

```bash
bundle exec rspec
```

Run tests with coverage:

```bash
COVERAGE=true bundle exec rspec
```

## Requirements

- Ruby >= 2.6.0

## License

The gem is available as open source under the terms of the MIT License. 