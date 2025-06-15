RSpec.describe Tapsilat::OrderListResponse do
  let(:list_data) do
    {
      'rows' => [
        {
          'id' => 1,
          'status' => 3,
          'amount' => 100.0,
          'paid_amount' => 100.0
        },
        {
          'id' => 2,
          'status' => 8,
          'amount' => 200.0,
          'paid_amount' => 0.0
        },
        {
          'id' => 3,
          'status' => 2,
          'amount' => 150.0,
          'paid_amount' => 0.0
        },
        {
          'id' => 4,
          'status' => 10,
          'amount' => 300.0,
          'paid_amount' => 300.0
        }
      ],
      'total' => 25,
      'page' => 2,
      'per_page' => 10,
      'total_pages' => 3
    }
  end

  let(:list_response) { described_class.new(list_data) }

  describe '#initialize' do
    it 'accepts hash data' do
      response = described_class.new(list_data)
      expect(response.total).to eq(25)
    end

    it 'accepts JSON string data' do
      response = described_class.new(list_data.to_json)
      expect(response.total).to eq(25)
    end
  end

  describe '#rows' do
    it 'returns array of OrderResponse objects' do
      rows = list_response.rows
      expect(rows).to be_an(Array)
      expect(rows.length).to eq(4)
      expect(rows.first).to be_a(Tapsilat::OrderResponse)
      expect(rows.first.status).to eq(3)
    end

    context 'when rows is empty' do
      let(:list_data) { { 'rows' => [] } }

      it 'returns empty array' do
        expect(list_response.rows).to eq([])
      end
    end

    context 'when rows is nil' do
      let(:list_data) { { 'rows' => nil } }

      it 'returns empty array' do
        expect(list_response.rows).to eq([])
      end
    end
  end

  describe 'pagination attributes' do
    it 'returns correct pagination values' do
      expect(list_response.total).to eq(25)
      expect(list_response.page).to eq(2)
      expect(list_response.per_page).to eq(10)
      expect(list_response.total_pages).to eq(3)
    end

    context 'when pagination data is missing' do
      let(:list_data) { {} }

      it 'returns default values' do
        expect(list_response.total).to eq(0)
        expect(list_response.page).to eq(1)
        expect(list_response.per_page).to eq(10)
        expect(list_response.total_pages).to eq(0)
      end
    end
  end

  describe 'pagination helper methods' do
    describe '#first_page?' do
      context 'when on first page' do
        let(:list_data) { { 'page' => 1 } }

        it 'returns true' do
          expect(list_response.first_page?).to be true
        end
      end

      context 'when not on first page' do
        it 'returns false' do
          expect(list_response.first_page?).to be false
        end
      end
    end

    describe '#last_page?' do
      context 'when on last page' do
        let(:list_data) { { 'page' => 3, 'total_pages' => 3 } }

        it 'returns true' do
          expect(list_response.last_page?).to be true
        end
      end

      context 'when not on last page' do
        it 'returns false' do
          expect(list_response.last_page?).to be false
        end
      end
    end

    describe '#has_next_page?' do
      context 'when there is a next page' do
        it 'returns true' do
          expect(list_response.has_next_page?).to be true
        end
      end

      context 'when on last page' do
        let(:list_data) { { 'page' => 3, 'total_pages' => 3 } }

        it 'returns false' do
          expect(list_response.has_next_page?).to be false
        end
      end
    end

    describe '#has_previous_page?' do
      context 'when there is a previous page' do
        it 'returns true' do
          expect(list_response.has_previous_page?).to be true
        end
      end

      context 'when on first page' do
        let(:list_data) { { 'page' => 1 } }

        it 'returns false' do
          expect(list_response.has_previous_page?).to be false
        end
      end
    end

    describe '#next_page' do
      context 'when there is a next page' do
        it 'returns next page number' do
          expect(list_response.next_page).to eq(3)
        end
      end

      context 'when on last page' do
        let(:list_data) { { 'page' => 3, 'total_pages' => 3 } }

        it 'returns nil' do
          expect(list_response.next_page).to be_nil
        end
      end
    end

    describe '#previous_page' do
      context 'when there is a previous page' do
        it 'returns previous page number' do
          expect(list_response.previous_page).to eq(1)
        end
      end

      context 'when on first page' do
        let(:list_data) { { 'page' => 1 } }

        it 'returns nil' do
          expect(list_response.previous_page).to be_nil
        end
      end
    end
  end

  describe 'filtering methods' do
    describe '#orders_with_status' do
      it 'returns orders with specified status' do
        paid_orders = list_response.orders_with_status(3)
        expect(paid_orders.length).to eq(1)
        expect(paid_orders.first.status).to eq(3)
      end
    end

    describe '#paid_orders' do
      it 'returns paid orders' do
        paid_orders = list_response.paid_orders
        expect(paid_orders.length).to eq(1)
        expect(paid_orders.first.status).to eq(3)
      end
    end

    describe '#pending_orders' do
      it 'returns pending orders' do
        pending_orders = list_response.pending_orders
        expect(pending_orders.length).to eq(1)
        expect(pending_orders.first.status).to eq(2)
      end
    end

    describe '#cancelled_orders' do
      it 'returns cancelled orders' do
        cancelled_orders = list_response.cancelled_orders
        expect(cancelled_orders.length).to eq(1)
        expect(cancelled_orders.first.status).to eq(8)
      end
    end
  end

  describe 'calculation methods' do
    describe '#total_amount' do
      it 'returns sum of all order amounts' do
        expect(list_response.total_amount).to eq(750.0)
      end
    end

    describe '#total_paid_amount' do
      it 'returns sum of all paid amounts' do
        expect(list_response.total_paid_amount).to eq(400.0)
      end
    end
  end

  describe 'utility methods' do
    describe '#empty?' do
      context 'when there are orders' do
        it 'returns false' do
          expect(list_response.empty?).to be false
        end
      end

      context 'when there are no orders' do
        let(:list_data) { { 'rows' => [] } }

        it 'returns true' do
          expect(list_response.empty?).to be true
        end
      end
    end

    describe '#count' do
      it 'returns number of orders in current page' do
        expect(list_response.count).to eq(4)
      end
    end

    describe '#to_h' do
      it 'returns the original data hash' do
        expect(list_response.to_h).to eq(list_data)
      end
    end

    describe '#to_json' do
      it 'returns JSON representation of the data' do
        expect(list_response.to_json).to eq(list_data.to_json)
      end
    end
  end
end
