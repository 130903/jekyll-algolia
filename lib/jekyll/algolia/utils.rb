# frozen_string_literal: true

require 'nokogiri'

module Jekyll
  module Algolia
    # Generic language-wide utils
    module Utils
      # Public: Allow redefining an instance method on the fly with a new one
      #
      # instance - The instance to overwrite
      # method - The method symbol to overwrite
      # block - The new block to use for replacing (as a proc)
      #
      # Solution found on
      # https://stackoverflow.com/questions/803020/redefining-a-single-ruby-method-on-a-single-instance-with-a-lambda/16631789
      def self.monkey_patch(instance, method, block)
        metaclass = class << instance; self; end
        metaclass.send(:define_method, method, block)
      end

      # Public: Convert a hash with string keys to a hash with symbol keys
      #
      # hash - The input hash, with string keys
      def self.keys_to_symbols(hash)
        Hash[hash.map { |key, value| [key.to_sym, value] }]
      end

      # Public: Check if a variable is an instance of a specific class
      #
      # input - the variable to test
      # classname - the string representation of the class
      def self.instance_of?(input, classname)
        return input.instance_of? Object.const_get(classname)
      rescue StandardError
        # The class might not even exist
        return false
      end

      # Public: Convert an HTML string to its content only
      #
      # html - String representation of the HTML node
      def self.html_to_text(html)
        return nil if html.nil?
        text = Nokogiri::HTML(html).text
        text.tr("\n", ' ').squeeze(' ').strip
      end

      # Public: Remove all keys with a nil value or an empty array from a hash
      #
      # hash - The input hash
      def self.compact_empty(hash)
        new_hash = {}
        hash.each do |key, value|
          next if value.nil?
          next if value.respond_to?(:empty?) && value.empty?
          new_hash[key] = value
        end
        new_hash
      end

      # Public: Check if a string matches a regex
      #
      # string - The string to test
      # regex - The regex to match against
      #
      # Newer versions of Ruby have easy ways to test this, but a wrapper is
      # needed for older versions.
      def self.match?(string, regex)
        # Ruby 2.4 introduces .match?
        return regex.match?(string) if regex.respond_to?(:match?)

        # Older versions of Ruby have to deal with =~ returning nil if no match
        # is found
        !(string =~ regex).nil?
      end

      # Public: Find an item from an array based on the value of one of its key
      #
      # items - The array of hashes to search
      # key - The key to search for
      # value - The value of the key to filter
      #
      # It is basically a wrapper around [].find, handling more edge-cases
      def self.find_by_key(items, key, value)
        return nil if items.nil?
        items.find do |item|
          item[key] == value
        end
      end
    end
  end
end
