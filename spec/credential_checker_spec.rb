require 'spec_helper'

describe(AlgoliaSearchCredentialChecker) do
  let(:config) do
    {
      'source' => fixture_path,
      'markdown_ext' => 'md,mkd',
      'algolia' => {
        'application_id' => 'APPID',
        'index_name' => 'INDEXNAME'
      }
    }
  end
  let(:checker) { AlgoliaSearchCredentialChecker.new(config) }

  describe 'api_key' do
    it 'returns nil if no key found' do
      # Given

      # When
      actual = checker.api_key

      # Then
      expect(actual).to be_nil
    end

    it 'reads from ENV var if set' do
      # Given
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')

      # When
      actual = checker.api_key

      # Then
      expect(actual).to eq 'APIKEY_FROM_ENV'
    end

    it 'reads from _algolia_api_key in source if set' do
      # Given
      checker.config['source'] = File.join(config['source'], 'api_key_dir')

      # When
      actual = checker.api_key

      # Then
      expect(actual).to eq 'APIKEY_FROM_FILE'
    end

    it 'reads from ENV before from file' do
      # Given
      checker.config['source'] = File.join(config['source'], 'api_key_dir')
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')

      # When
      actual = checker.api_key

      # Then
      expect(actual).to eq 'APIKEY_FROM_ENV'
    end
  end

  describe 'assert_valid' do
    before(:each) do
      allow(checker.logger).to receive(:display)
    end
    it 'should display error if no api key' do
      # Given
      allow(checker).to receive(:api_key).and_return nil

      # Then
      expect(-> { checker.assert_valid }).to raise_error SystemExit
      expect(checker.logger).to have_received(:display).with('api_key_missing')
    end

    it 'should display error if no application id' do
      # Given
      checker.config['algolia'] = {
        'application_id' => nil,
        'index_name' => 'INDEX_NAME'
      }
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')

      # Then
      expect(-> { checker.assert_valid }).to raise_error SystemExit
      expect(checker.logger)
        .to have_received(:display)
        .with('application_id_missing')
    end

    it 'should display error if no index name' do
      # Given
      checker.config['algolia'] = {
        'application_id' => 'APPLICATION_ID',
        'index_name' => nil
      }
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')

      # Then
      expect(-> { checker.assert_valid }).to raise_error SystemExit
      expect(checker.logger)
        .to have_received(:display)
        .with('index_name_missing')
    end

    it 'should init the Algolia client' do
      # Given
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')
      allow(Algolia).to receive(:init)

      # When
      checker.assert_valid

      # Then
      expect(Algolia).to have_received(:init).with(
        application_id: 'APPID',
        api_key: 'APIKEY_FROM_ENV'
      )
    end
  end
end
