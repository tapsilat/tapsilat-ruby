RSpec.describe Tapsilat::Orders, :configured do
  let(:client) { Tapsilat::Client.new }
  let(:orders) { client.orders }

  describe '#initialize' do
    it 'accepts a client instance' do
      expect(orders.instance_variable_get(:@client)).to eq(client)
    end
  end

  describe '.status_text' do
    it 'returns correct status text for known status codes' do
      expect(described_class.status_text(1)).to eq('Received')
      expect(described_class.status_text(3)).to eq('Paid')
      expect(described_class.status_text(8)).to eq('Cancelled')
      expect(described_class.status_text(9)).to eq('Completed')
    end

    it "returns 'Unknown' for unknown status codes" do
      expect(described_class.status_text(999)).to eq('Unknown')
    end
  end

  describe '#build_order' do
    let(:buyer_data) do
      {
        id: 'BY789',
        name: 'John',
        surname: 'Doe',
        email: 'john@doe.com',
        gsm_number: '905350000000',
        identity_number: '74300864791',
        city: 'Istanbul',
        country: 'Turkey',
        zip_code: '34732',
        ip: '127.0.0.1'
      }
    end

    let(:billing_address_data) do
      {
        billing_type: 'PERSONAL',
        citizenship: 'TR',
        vat_number: '74300864791',
        city: 'Istanbul',
        district: 'Uskudar',
        country: 'TR',
        address: 'Uskudar/Istanbul',
        zip_code: '34732',
        contact_name: 'John Doe',
        contact_phone: '+905350000000'
      }
    end

    let(:basket_items_data) do
      [
        {
          id: 'BI101',
          price: 100.0,
          quantity: 1,
          name: 'Test Product',
          category1: 'Electronics',
          category2: 'Phones',
          item_type: 'PHYSICAL'
        }
      ]
    end

    it 'builds a complete order structure' do
      order = orders.build_order(
        locale: 'tr',
        amount: 100.0,
        currency: 'TRY',
        buyer: buyer_data,
        billing_address: billing_address_data,
        basket_items: basket_items_data,
        payment_success_url: 'https://example.com/success',
        payment_failure_url: 'https://example.com/failure'
      )

      expect(order[:locale]).to eq('tr')
      expect(order[:amount]).to eq(100.0)
      expect(order[:currency]).to eq('TRY')
      expect(order[:buyer][:name]).to eq('John')
      expect(order[:billing_address][:city]).to eq('Istanbul')
      expect(order[:basket_items]).to be_an(Array)
      expect(order[:basket_items].first[:name]).to eq('Test Product')
      expect(order[:payment_success_url]).to eq('https://example.com/success')
      expect(order[:payment_failure_url]).to eq('https://example.com/failure')
    end

    it 'sets default values for optional parameters' do
      order = orders.build_order(
        locale: 'tr',
        amount: 100.0,
        currency: 'TRY',
        buyer: buyer_data,
        billing_address: billing_address_data,
        basket_items: basket_items_data
      )

      expect(order[:paid_amount]).to eq(0.0)
      expect(order[:tax_amount]).to eq(0.0)
      expect(order[:three_d_force]).to be(false)
      expect(order[:enabled_installments]).to eq([1])
      expect(order[:partial_payment]).to be(false)
      expect(order[:payment_options]).to eq(['credit_card'])
    end

    it 'converts amounts to float' do
      order = orders.build_order(
        locale: 'tr',
        amount: '100.50',
        currency: 'TRY',
        buyer: buyer_data,
        billing_address: billing_address_data,
        basket_items: [basket_items_data.first.merge(price: '50.25')]
      )

      expect(order[:amount]).to eq(100.5)
      expect(order[:basket_items].first[:price]).to eq(50.25)
    end
  end

  # API tests with real API
  describe '#create' do
    let(:order_data) do
      {
        locale: 'tr',
        amount: 100.0,
        currency: 'TRY',
        buyer: {
          name: 'John',
          surname: 'Doe',
          email: 'john@doe.com',
          gsm_number: '905350000000',
          identity_number: '74300864791',
          city: 'Istanbul',
          country: 'Turkey',
          zip_code: '34732',
          ip: '127.0.0.1'
        },
        billing_address: {
          billing_type: 'PERSONAL',
          city: 'Istanbul',
          country: 'TR',
          district: 'Uskudar',
          address: 'Uskudar/Istanbul',
          zip_code: '34732',
          contact_name: 'John Doe',
          contact_phone: '+905350000000'
        },
        basket_items: [{
          id: 'BI101',
          price: 100.0,
          quantity: 1,
          name: 'Test Product',
          category1: 'Electronics',
          category2: 'Phones',
          item_type: 'PHYSICAL'
        }]
      }
    end

    it 'creates an order successfully with real API' do
      response = orders.create(order_data)
      expect(response).to be_a(Tapsilat::OrderResponse)
      expect(response.data['order_id']).not_to be_nil
      expect(response.data['reference_id']).not_to be_nil
    end

    context 'when required fields are missing' do
      let(:invalid_order_data) { { locale: 'tr' } }

      it 'raises OrderValidationError' do
        expect { orders.create(invalid_order_data) }.to raise_error(Tapsilat::OrderValidationError, /Missing required field/)
      end
    end

    context 'when amount is invalid' do
      let(:invalid_order_data) do
        order_data.merge(amount: -10)
      end

      it 'raises OrderValidationError' do
        expect { orders.create(invalid_order_data) }.to raise_error(Tapsilat::OrderValidationError, /Amount must be a positive number/)
      end
    end

    context 'when currency is invalid' do
      let(:invalid_order_data) do
        order_data.merge(currency: 'INVALID')
      end

      it 'raises OrderValidationError' do
        expect { orders.create(invalid_order_data) }.to raise_error(Tapsilat::OrderValidationError, /Invalid currency/)
      end
    end

    context 'when buyer email is invalid' do
      let(:invalid_order_data) do
        order_data.merge(buyer: { name: 'John', surname: 'Doe', email: 'invalid-email' })
      end

      it 'raises OrderValidationError' do
        expect { orders.create(invalid_order_data) }.to raise_error(Tapsilat::OrderValidationError, /Invalid email format/)
      end
    end

    context 'when basket items are empty' do
      let(:invalid_order_data) do
        order_data.merge(basket_items: [])
      end

      it 'raises OrderValidationError' do
        expect { orders.create(invalid_order_data) }.to raise_error(Tapsilat::OrderValidationError, /Basket items cannot be empty/)
      end
    end

    context 'when validation errors occur' do
      it 'raises OrderValidationError when amount is invalid' do
        invalid_data = order_data.merge(amount: -10)
        expect { orders.create(invalid_data) }.to raise_error(Tapsilat::OrderValidationError)
      end

      it 'raises OrderValidationError when currency is invalid' do
        invalid_data = order_data.merge(currency: 'INVALID')
        expect { orders.create(invalid_data) }.to raise_error(Tapsilat::OrderValidationError)
      end

      it 'raises OrderValidationError when basket items are empty' do
        invalid_data = order_data.merge(basket_items: [])
        expect { orders.create(invalid_data) }.to raise_error(Tapsilat::OrderValidationError)
      end

      it 'raises OrderValidationError when buyer email is invalid' do
        invalid_data = order_data.merge(buyer: { name: 'John', surname: 'Doe', email: 'invalid-email' })
        expect { orders.create(invalid_data) }.to raise_error(Tapsilat::OrderValidationError)
      end

      it 'raises OrderValidationError when required fields are missing' do
        expect { orders.create({}) }.to raise_error(Tapsilat::OrderValidationError)
      end
    end
  end

  describe '#list', :integration do
    it 'returns an OrderListResponse with real API' do
      response = orders.list
      expect(response).to be_a(Tapsilat::OrderListResponse)
      expect(response.rows).to be_an(Array)
      expect(response.total).to be_a(Integer)
      expect(response.page).to be_a(Integer)
    end

    it 'passes parameters correctly to the real API' do
      response = orders.list(page: 1, per_page: 5)
      expect(response).to be_a(Tapsilat::OrderListResponse)
      expect(response.page).to eq(1)
    end
  end

  describe '#get', :configured do
    let(:order_data) do
      {
        locale: 'tr',
        amount: 100.0,
        currency: 'TRY',
        buyer: {
          name: 'John',
          surname: 'Doe',
          email: 'john@doe.com',
          gsm_number: '905350000000',
          identity_number: '74300864791',
          city: 'Istanbul',
          country: 'Turkey',
          zip_code: '34732',
          ip: '127.0.0.1'
        },
        billing_address: {
          billing_type: 'PERSONAL',
          city: 'Istanbul',
          country: 'TR',
          district: 'Uskudar',
          address: 'Uskudar/Istanbul',
          zip_code: '34732',
          contact_name: 'John Doe',
          contact_phone: '+905350000000'
        },
        basket_items: [{
          id: 'BI101',
          price: 100.0,
          quantity: 1,
          name: 'Test Product',
          category1: 'Electronics',
          category2: 'Phones',
          item_type: 'PHYSICAL'
        }]
      }
    end

    context 'when order ID is nil' do
      it 'raises OrderValidationError' do
        expect { orders.get(nil) }.to raise_error(Tapsilat::OrderValidationError, /Order ID cannot be nil or empty/)
      end
    end

    context 'when order ID is empty' do
      it 'raises OrderValidationError' do
        expect { orders.get('') }.to raise_error(Tapsilat::OrderValidationError, /Order ID cannot be nil or empty/)
      end
    end

    context 'when getting details of a created order' do
      it 'returns order details with real API' do
        # First create an order
        create_response = orders.create(order_data)
        expect(create_response).to be_a(Tapsilat::OrderResponse)

        reference_id = create_response.reference_id
        expect(reference_id).not_to be_nil

        # Then get its details
        get_response = orders.get(reference_id)
        expect(get_response).to be_a(Tapsilat::OrderResponse)
        expect(get_response.reference_id).to eq(reference_id)
        expect(get_response.amount).to eq(100.0)
        expect(get_response.currency).to eq('TRY')
        expect(get_response.locale).to eq('tr')
        expect(get_response.buyer).not_to be_nil
        expect(get_response.billing_address).not_to be_nil
        expect(get_response.basket_items).to be_an(Array)
        expect(get_response.basket_items.size).to eq(1)

        puts "Retrieved order #{reference_id}: status=#{get_response.status_text}, amount=#{get_response.amount}"
      end
    end

    context 'when order is not found' do
      it 'raises OrderNotFoundError with real API' do
        # Test with a non-existent order ID
        fake_order_id = 'non-existent-order-id-67890'

        expect { orders.get(fake_order_id) }.to raise_error do |error|
          expect(error).to be_a(Tapsilat::OrderNotFoundError).or be_a(Tapsilat::OrderAPIError)
        end
      end
    end
  end

  describe '#get_status', :configured do
    let(:order_data) do
      {
        locale: 'tr',
        amount: 100.0,
        currency: 'TRY',
        buyer: {
          name: 'John',
          surname: 'Doe',
          email: 'john@doe.com',
          gsm_number: '905350000000',
          identity_number: '74300864791',
          city: 'Istanbul',
          country: 'Turkey',
          zip_code: '34732',
          ip: '127.0.0.1'
        },
        billing_address: {
          billing_type: 'PERSONAL',
          city: 'Istanbul',
          country: 'TR',
          district: 'Uskudar',
          address: 'Uskudar/Istanbul',
          zip_code: '34732',
          contact_name: 'John Doe',
          contact_phone: '+905350000000'
        },
        basket_items: [{
          id: 'BI101',
          price: 100.0,
          quantity: 1,
          name: 'Test Product',
          category1: 'Electronics',
          category2: 'Phones',
          item_type: 'PHYSICAL'
        }]
      }
    end

    context 'when order ID is nil' do
      it 'raises OrderValidationError' do
        expect { orders.get_status(nil) }.to raise_error(Tapsilat::OrderValidationError, /Order ID cannot be nil or empty/)
      end
    end

    context 'when order ID is empty' do
      it 'raises OrderValidationError' do
        expect { orders.get_status('') }.to raise_error(Tapsilat::OrderValidationError, /Order ID cannot be nil or empty/)
      end
    end

    context 'when checking status of a created order' do
      it 'returns order status with real API' do
        # First create an order
        create_response = orders.create(order_data)
        expect(create_response).to be_a(Tapsilat::OrderResponse)

        reference_id = create_response.reference_id
        expect(reference_id).not_to be_nil

        # Then check its status
        status_response = orders.get_status(reference_id)
        expect(status_response).to be_a(Tapsilat::OrderStatusResponse)
        expect(status_response.status).to be_a(String)
        expect(status_response.status).not_to be_empty

        puts "Created order #{reference_id} with status: #{status_response.status}"
      end
    end

    context 'when order is not found' do
      it 'raises OrderNotFoundError with real API' do
        # Test with a non-existent order ID
        fake_order_id = 'non-existent-order-id-12345'

        expect { orders.get_status(fake_order_id) }.to raise_error do |error|
          expect(error).to be_a(Tapsilat::OrderNotFoundError).or be_a(Tapsilat::OrderAPIError)
        end
      end
    end
  end
end
