require 'spec_helper'

describe(Jekyll::Algolia::Configurator) do
  let(:current) { Jekyll::Algolia::Configurator }
  let(:config) { {} }
  before do
    allow(Jekyll::Algolia).to receive(:config).and_return(config)
  end

  describe '.get' do
    let(:config) { { 'foo' => 'bar' } }

    subject { current.get('foo') }

    it { should eq 'bar' }
  end

  describe '.algolia' do
    subject { current.algolia(input) }

    context 'with an algolia config defined' do
      let(:config) { { 'algolia' => { 'foo' => 'bar' } } }

      context 'with a config option that is set' do
        let(:input) { 'foo' }
        it { should eq 'bar' }
      end
      context 'with a config option that is not set' do
        let(:input) { 'baz' }
        it { should eq nil }
      end
      describe 'should get the default nodes_to_index' do
        let(:input) { 'nodes_to_index' }
        it { should eq 'p' }
      end
      describe 'should get the default extensions_to_index' do
        before(:each) do
          allow(current)
            .to receive(:default_extensions_to_index)
            .and_return('foo')
        end

        let(:input) { 'extensions_to_index' }
        it { should eq 'foo' }
      end
    end

    context 'with no algolia config defined' do
      let(:input) { 'foo' }
      it { should eq nil }

      describe 'should get the default nodes_to_index' do
        let(:input) { 'nodes_to_index' }
        it { should eq 'p' }
      end
    end
  end

  describe '.default_extensions_to_index' do
    subject { current.default_extensions_to_index }

    before do
      allow(current)
        .to receive(:get)
        .with('markdown_ext')
        .and_return('foo,bar')
    end

    it { should include('html') }
    it { should include('foo') }
    it { should include('bar') }
  end

  describe '.default_files_to_exclude' do
    subject { current.default_files_to_exclude }

    before do
      allow(current)
        .to receive(:algolia)
        .with('extensions_to_index')
        .and_return(%w[foo bar])
    end

    it { should include('index.foo') }
    it { should include('index.bar') }
  end

  describe '.index_name' do
    subject { current.index_name }

    describe 'should return nil if none configured' do
      it { should eq nil }
    end
    describe 'should return the value in _config.yml if set' do
      let(:config) { { 'algolia' => { 'index_name' => 'foo' } } }
      it { should eq 'foo' }
    end
    describe 'should return the value in ENV is set' do
      before { stub_const('ENV', 'ALGOLIA_INDEX_NAME' => 'bar') }
      it { should eq 'bar' }
    end
    describe 'should prefer the value in ENV rather than config if set' do
      let(:config) { { 'algolia' => { 'index_name' => 'foo' } } }
      before { stub_const('ENV', 'ALGOLIA_INDEX_NAME' => 'bar') }
      it { should eq 'bar' }
    end
  end

  describe '.application_id' do
    subject { current.application_id }

    describe 'should return nil if none configured' do
      it { should eq nil }
    end
    describe 'should return the value in _config.yml if set' do
      let(:config) { { 'algolia' => { 'application_id' => 'foo' } } }
      it { should eq 'foo' }
    end
    describe 'should return the value in ENV is set' do
      let(:config) { {} }
      before { stub_const('ENV', 'ALGOLIA_APPLICATION_ID' => 'bar') }
      it { should eq 'bar' }
    end
    describe 'should prefer the value in ENV rather than config if set' do
      let(:config) { { 'algolia' => { 'application_id' => 'foo' } } }
      before { stub_const('ENV', 'ALGOLIA_APPLICATION_ID' => 'bar') }
      it { should eq 'bar' }
    end
  end

  describe '.api_key' do
    subject { current.api_key }

    describe 'should return nil if none configured' do
      it { should eq nil }
    end
    describe 'should return the value in ENV is set' do
      before { stub_const('ENV', 'ALGOLIA_API_KEY' => 'bar') }
      it { should eq 'bar' }
    end
    describe 'should return the value in _algolia_api_key file' do
      let(:config) { { 'source' => './spec/site' } }
      it { should eq 'APIKEY_FROM_FILE' }
    end
    describe 'should prefer the value in ENV rather than in the file' do
    end
  end
end
