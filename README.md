# Tapsilat Ruby Client

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
orders = client.orders.list
orders.rows.each do |order|
  puts "#{order.reference_id}: #{order.status_text}"
end
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

- Order creation and management
- Built-in validation and error handling
- Automatic retry mechanism for network errors
- Comprehensive error types for different failure scenarios
- Pagination support for order listings
- Response objects with convenient helper methods
- Full order status tracking

## Requirements

- Ruby >= 2.6.0

## License

The gem is available as open source under the terms of the MIT License. 