RSpec.describe Tapsilat::Orders, :configured do
  let(:client) { Tapsilat::Client.new }
  let(:orders) { described_class.new(client) }

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

  describe '#create' do
    let(:order_data) do
      {
        locale: 'tr',
        amount: 100.0,
        currency: 'TRY',
        buyer: { name: 'John', surname: 'Doe', email: 'john@doe.com' },
        billing_address: { billing_type: 'PERSONAL', city: 'Istanbul', country: 'TR' },
        basket_items: [{ id: 'BI101', price: 100.0, quantity: 1, name: 'Test Product' }]
      }
    end

    context 'when order data is valid' do
      before do
        stub_request(:post, 'https://api.tapsilat.com/orders')
          .with(body: order_data.to_json)
          .to_return(status: 201, body: '{"id": 123, "status": "created"}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'creates an order successfully' do
        response = orders.create(order_data)
        expect(response).to be_a(Tapsilat::OrderResponse)
        expect(response.data['id']).to eq(123)
      end
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

    context 'when API returns an error response' do
      before do
        stub_request(:post, 'https://api.tapsilat.com/orders')
          .with(body: order_data.to_json)
          .to_return(status: 200, body: '{"status": "error", "message": "Invalid payment method"}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises OrderCreationError' do
        expect { orders.create(order_data) }.to raise_error(Tapsilat::OrderCreationError, /Invalid payment method/)
      end
    end

    context 'when API returns 401 unauthorized' do
      before do
        stub_request(:post, 'https://api.tapsilat.com/orders')
          .with(body: order_data.to_json)
          .to_return(status: 401, body: '{"error": "Unauthorized"}')
      end

      it 'raises OrderAPIError' do
        expect { orders.create(order_data) }.to raise_error(Tapsilat::OrderAPIError, /Invalid API credentials/)
      end
    end

    context 'when API returns 500 server error' do
      before do
        stub_request(:post, 'https://api.tapsilat.com/orders')
          .with(body: order_data.to_json)
          .to_return(status: 500, body: '{"error": "Internal Server Error"}')
      end

      it 'raises OrderAPIError' do
        expect { orders.create(order_data) }.to raise_error(Tapsilat::OrderAPIError, /Server error/)
      end
    end

    context 'when network timeout occurs' do
      before do
        stub_request(:post, 'https://api.tapsilat.com/orders').to_timeout
      end

      it 'retries and eventually raises OrderError' do
        expect { orders.create(order_data) }.to raise_error(Tapsilat::OrderError, /Max retry attempts.*exceeded/)
      end
    end
  end

  describe '#get' do
    context 'when order exists' do
      before do
        stub_request(:get, 'https://api.tapsilat.com/orders/123')
          .to_return(status: 200, body: '{"id": 123, "status": 3, "amount": 100.0}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an OrderResponse' do
        response = orders.get(123)
        expect(response).to be_a(Tapsilat::OrderResponse)
        expect(response.status).to eq(3)
        expect(response.amount).to eq(100.0)
      end
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

    context 'when order does not exist' do
      before do
        stub_request(:get, 'https://api.tapsilat.com/orders/999')
          .to_return(status: 404)
      end

      it 'raises OrderNotFoundError' do
        expect { orders.get(999) }.to raise_error(Tapsilat::OrderNotFoundError, /Order with ID '999' not found/)
      end
    end

    context 'when API returns 401 unauthorized' do
      before do
        stub_request(:get, 'https://api.tapsilat.com/orders/123')
          .to_return(status: 401)
      end

      it 'raises OrderAPIError' do
        expect { orders.get(123) }.to raise_error(Tapsilat::OrderAPIError, /Invalid API credentials/)
      end
    end
  end

  describe '#list' do
    context 'when listing orders' do
      before do
        stub_request(:get, 'https://api.tapsilat.com/orders/list')
          .with(query: { page: 1, per_page: 10 })
          .to_return(
            status: 200,
            body: {
              rows: [
                { id: 1, status: 3, amount: 100.0 },
                { id: 2, status: 8, amount: 200.0 }
              ],
              total: 2,
              page: 1,
              per_page: 10,
              total_pages: 1
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns an OrderListResponse' do
        response = orders.list
        expect(response).to be_a(Tapsilat::OrderListResponse)
        expect(response.rows.length).to eq(2)
        expect(response.total).to eq(2)
        expect(response.page).to eq(1)
      end
    end

    context 'when passing parameters' do
      before do
        stub_request(:get, 'https://api.tapsilat.com/orders/list')
          .with(query: { page: 2, per_page: 5, start_date: '2023-01-01' })
          .to_return(status: 200, body: '{"rows": [], "total": 0}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'passes parameters correctly' do
        orders.list(page: 2, per_page: 5, start_date: '2023-01-01')
        expect(WebMock).to have_requested(:get, 'https://api.tapsilat.com/orders/list')
          .with(query: { page: 2, per_page: 5, start_date: '2023-01-01' })
      end
    end

    context 'when API returns 401 unauthorized' do
      before do
        stub_request(:get, 'https://api.tapsilat.com/orders/list')
          .to_return(status: 401)
      end

      it 'raises OrderAPIError' do
        expect { orders.list }.to raise_error(Tapsilat::OrderAPIError, /Invalid API credentials/)
      end
    end
  end
end
