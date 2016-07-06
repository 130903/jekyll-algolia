if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
end

require 'awesome_print'
require 'jekyll'
require_relative './spec_helper_simplecov.rb'
require './lib/push.rb'
require './lib/utils.rb'

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.fail_fast = true
  config.run_all_when_everything_filtered = true
end

# Disabling the logs
Jekyll.logger.log_level = :error

# Create a Jekyll::Site instance, patched with a `file_by_name` method
def get_site(config = {}, options = {})
  default_options = {
    mock_write_method: true,
    process: true
  }
  options = default_options.merge(options)

  config = config.merge(
    source: fixture_path
  )
  config = Jekyll.configuration(config)

  site = AlgoliaSearchJekyllPush.init_options({}, options, config)
                                .jekyll_new(config)

  def site.file_by_name(file_name)
    files = {}

    # We get the list of all classic files
    each_site_file do |file|
      files[file.path] = file
    end

    # If we have an exact match, we use that one:
    return files[file_name] if files.key?(file_name)

    # Otherwise we try to find a key that is loosely matching
    keys = files.keys
    values = files.values

    keys.each_with_index do |key, index|
      return values[index] if key =~ /#{file_name}$/
    end

    nil
  end

  allow(site).to receive(:write) if options[:mock_write_method]

  site.process if options[:process]
  site
end

# Return the fixture path, according to the current Jekyll version being tested
def fixture_path
  jekyll_version = Jekyll::VERSION[0]
  fixture_path = "./spec/fixtures/jekyll_version_#{jekyll_version}"
  File.expand_path(fixture_path)
end

# Check the current Jekyll version
def restrict_jekyll_version(more_than: nil, less_than: nil)
  AlgoliaSearchUtils.restrict_jekyll_version(
    more_than: more_than,
    less_than: less_than
  )
end
