RSpec.describe Tapsilat do
  it 'has a version number' do
    expect(Tapsilat::VERSION).not_to be_nil
  end

  describe '.configure' do
    it 'allows configuration of base_url and api_token' do
      described_class.configure do |config|
        config.base_url = 'https://acquiring.tapsilat.dev/api/v1'
        config.api_token = 'test-token'
      end

      expect(described_class.base_url).to eq('https://acquiring.tapsilat.dev/api/v1')
      expect(described_class.api_token).to eq('test-token')
    end
  end

  describe '.configured?' do
    context 'when both base_url and api_token are set' do
      before do
        described_class.configure do |config|
          config.base_url = 'https://acquiring.tapsilat.dev/api/v1'
          config.api_token = 'test-token'
        end
      end

      it 'returns true' do
        expect(described_class.configured?).to be true
      end
    end

    context 'when base_url is missing' do
      before do
        described_class.configure do |config|
          config.api_token = 'test-token'
        end
      end

      it 'returns false' do
        expect(described_class.configured?).to be false
      end
    end

    context 'when api_token is missing' do
      before do
        described_class.configure do |config|
          config.base_url = 'https://acquiring.tapsilat.dev/api/v1'
        end
      end

      it 'returns false' do
        expect(described_class.configured?).to be false
      end
    end
  end

  describe '.reset!' do
    it 'clears the configuration' do
      described_class.configure do |config|
        config.base_url = 'https://acquiring.tapsilat.dev/api/v1'
        config.api_token = 'test-token'
      end

      expect(described_class.configured?).to be true

      described_class.reset!

      expect(described_class.configured?).to be false
      expect(described_class.base_url).to be_nil
      expect(described_class.api_token).to be_nil
    end
  end
end
