RSpec.describe Tapsilat::OrderResponse do
  let(:order_data) do
    {
      'locale' => 'tr',
      'reference_id' => 'REF123',
      'external_reference_id' => 'EXT456',
      'amount' => 100.5,
      'total' => 105.0,
      'paid_amount' => 100.5,
      'refunded_amount' => 0.0,
      'created_at' => '2023-01-01T10:00:00Z',
      'currency' => 'TRY',
      'status' => 3,
      'status_enum' => 'PAID',
      'buyer' => {
        'name' => 'John',
        'surname' => 'Doe',
        'email' => 'john@doe.com'
      },
      'shipping_address' => {
        'city' => 'Istanbul',
        'country' => 'TR'
      },
      'billing_address' => {
        'city' => 'Istanbul',
        'country' => 'TR'
      },
      'basket_items' => [
        {
          'id' => 'BI101',
          'name' => 'Test Product',
          'price' => 100.5,
          'quantity' => 1,
          'refundable_amount' => 100.5,
          'paid_amount' => 100.5
        }
      ],
      'checkout_design' => 'default',
      'payment_terms' => [],
      'payment_failure_url' => 'https://example.com/failure',
      'payment_success_url' => 'https://example.com/success',
      'checkout_url' => 'https://checkout.tapsilat.com/123',
      'conversation_id' => 'CONV123',
      'payment_options' => ['credit_card'],
      'metadata' => []
    }
  end

  let(:order_response) { described_class.new(order_data) }

  describe '#initialize' do
    it 'accepts hash data' do
      response = described_class.new(order_data)
      expect(response.locale).to eq('tr')
    end

    it 'accepts JSON string data' do
      response = described_class.new(order_data.to_json)
      expect(response.locale).to eq('tr')
    end
  end

  describe 'attribute readers' do
    it 'returns correct values for all attributes' do
      expect(order_response.locale).to eq('tr')
      expect(order_response.reference_id).to eq('REF123')
      expect(order_response.external_reference_id).to eq('EXT456')
      expect(order_response.amount).to eq(100.5)
      expect(order_response.total).to eq(105.0)
      expect(order_response.paid_amount).to eq(100.5)
      expect(order_response.refunded_amount).to eq(0.0)
      expect(order_response.created_at).to eq('2023-01-01T10:00:00Z')
      expect(order_response.currency).to eq('TRY')
      expect(order_response.status).to eq(3)
      expect(order_response.status_enum).to eq('PAID')
      expect(order_response.buyer).to eq(order_data['buyer'])
      expect(order_response.shipping_address).to eq(order_data['shipping_address'])
      expect(order_response.billing_address).to eq(order_data['billing_address'])
      expect(order_response.basket_items).to eq(order_data['basket_items'])
      expect(order_response.checkout_design).to eq('default')
      expect(order_response.payment_terms).to eq([])
      expect(order_response.payment_failure_url).to eq('https://example.com/failure')
      expect(order_response.payment_success_url).to eq('https://example.com/success')
      expect(order_response.checkout_url).to eq('https://checkout.tapsilat.com/123')
      expect(order_response.conversation_id).to eq('CONV123')
      expect(order_response.payment_options).to eq(['credit_card'])
      expect(order_response.metadata).to eq([])
    end
  end

  describe '#status_text' do
    it 'returns correct status text' do
      expect(order_response.status_text).to eq('Paid')
    end

    context 'when status is unknown' do
      let(:order_data) { { 'status' => 999 } }

      it "returns 'Unknown'" do
        expect(order_response.status_text).to eq('Unknown')
      end
    end
  end

  describe 'status helper methods' do
    describe '#paid?' do
      context 'when status is 3 (Paid)' do
        it 'returns true' do
          expect(order_response.paid?).to be true
        end
      end

      context 'when status is not 3' do
        let(:order_data) { { 'status' => 2 } }

        it 'returns false' do
          expect(order_response.paid?).to be false
        end
      end
    end

    describe '#cancelled?' do
      context 'when status is 8 (Cancelled)' do
        let(:order_data) { { 'status' => 8 } }

        it 'returns true' do
          expect(order_response.cancelled?).to be true
        end
      end

      context 'when status is not 8' do
        it 'returns false' do
          expect(order_response.cancelled?).to be false
        end
      end
    end

    describe '#completed?' do
      context 'when status is 9 (Completed)' do
        let(:order_data) { { 'status' => 9 } }

        it 'returns true' do
          expect(order_response.completed?).to be true
        end
      end

      context 'when status is not 9' do
        it 'returns false' do
          expect(order_response.completed?).to be false
        end
      end
    end

    describe '#refunded?' do
      context 'when status is 10 (Refunded)' do
        let(:order_data) { { 'status' => 10 } }

        it 'returns true' do
          expect(order_response.refunded?).to be true
        end
      end

      context 'when status is 15 (Partially refunded)' do
        let(:order_data) { { 'status' => 15 } }

        it 'returns true' do
          expect(order_response.refunded?).to be true
        end
      end

      context 'when status is not refunded' do
        it 'returns false' do
          expect(order_response.refunded?).to be false
        end
      end
    end

    describe '#pending_payment?' do
      context 'when status is 2 (Unpaid)' do
        let(:order_data) { { 'status' => 2 } }

        it 'returns true' do
          expect(order_response.pending_payment?).to be true
        end
      end

      context 'when status is 7 (Waiting for payment)' do
        let(:order_data) { { 'status' => 7 } }

        it 'returns true' do
          expect(order_response.pending_payment?).to be true
        end
      end

      context 'when status is not pending payment' do
        it 'returns false' do
          expect(order_response.pending_payment?).to be false
        end
      end
    end

    describe '#failed?' do
      context 'when status is 11 (Fraud)' do
        let(:order_data) { { 'status' => 11 } }

        it 'returns true' do
          expect(order_response.failed?).to be true
        end
      end

      context 'when status is 12 (Rejected)' do
        let(:order_data) { { 'status' => 12 } }

        it 'returns true' do
          expect(order_response.failed?).to be true
        end
      end

      context 'when status is 13 (Failure)' do
        let(:order_data) { { 'status' => 13 } }

        it 'returns true' do
          expect(order_response.failed?).to be true
        end
      end

      context 'when status is not failed' do
        it 'returns false' do
          expect(order_response.failed?).to be false
        end
      end
    end
  end

  describe '#total_refundable_amount' do
    it 'sums refundable amounts from basket items' do
      expect(order_response.total_refundable_amount).to eq(100.5)
    end

    context 'when basket items have no refundable amounts' do
      let(:order_data) do
        {
          'basket_items' => [
            { 'id' => 'BI101', 'name' => 'Test Product' },
            { 'id' => 'BI102', 'name' => 'Test Product 2' }
          ]
        }
      end

      it 'returns 0.0' do
        expect(order_response.total_refundable_amount).to eq(0.0)
      end
    end
  end

  describe '#total_paid_amount_from_items' do
    it 'sums paid amounts from basket items' do
      expect(order_response.total_paid_amount_from_items).to eq(100.5)
    end

    context 'when basket items have no paid amounts' do
      let(:order_data) do
        {
          'basket_items' => [
            { 'id' => 'BI101', 'name' => 'Test Product' },
            { 'id' => 'BI102', 'name' => 'Test Product 2' }
          ]
        }
      end

      it 'returns 0.0' do
        expect(order_response.total_paid_amount_from_items).to eq(0.0)
      end
    end
  end

  describe '#to_h' do
    it 'returns the original data hash' do
      expect(order_response.to_h).to eq(order_data)
    end
  end

  describe '#to_json' do
    it 'returns JSON representation of the data' do
      expect(order_response.to_json).to eq(order_data.to_json)
    end
  end
end
