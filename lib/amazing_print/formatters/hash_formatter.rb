# frozen_string_literal: true

require 'json'

require_relative 'base_formatter'
require_relative '../json_helper'

module AmazingPrint
  module Formatters
    class HashFormatter < BaseFormatter
      include AmazingPrint::JSONHelper

      VALID_HASH_FORMATS = %i[json rocket symbol].freeze

      class InvalidHashFormatError < StandardError; end

      attr_reader :hash, :inspector, :options

      def initialize(hash, inspector)
        super()
        @hash = hash
        @inspector = inspector
        @options = inspector.options

        puts "DEBUG hash_format: #{options[:hash_format]}"
        unless VALID_HASH_FORMATS.include?(options[:hash_format])
          raise(InvalidHashFormatError, "Invalid hash_format: #{options[:hash_format].inspect}. " \
                                        "Must be one of #{VALID_HASH_FORMATS}")
        end
      end

      def format
        if hash.empty?
          empty_hash
        elsif multiline_hash?
          multiline_hash
        else
          simple_hash
        end
      end

      private

      def empty_hash
        '{}'
      end

      def multiline_hash?
        options[:multiline]
      end

      def multiline_hash
        ["{\n", printable_hash.join(",\n"), "\n#{outdent}}"].join
      end

      def simple_hash
        "{ #{printable_hash.join(', ')} }"
      end

      def printable_hash
        data = printable_keys
        width = left_width(data)
        # require 'pry'; binding.pry

        data.map! do |key, value|
          indented do
            case options[:hash_format]
            when :json
              json_syntax(key, value, width)
            when :rocket
              pre_ruby19_syntax(key, value, width)
            when :symbol
              ruby19_syntax(key, value, width)
            end
          end
        end

        should_be_limited? ? limited(data, width, is_hash: true) : data
      end

      def left_width(keys)
        result = max_key_width(keys)
        result += indentation if options[:indent].positive?
        result
      end

      def max_key_width(keys)
        keys.map { |key, _value| key.to_s.size }.max || 0
      end

      def printable_keys
        keys = hash.keys

        keys.sort! { |a, b| a.to_s <=> b.to_s } if options[:sort_keys]

        keys.map! do |key|
          plain_single_line do
            [inspector.awesome(key), hash[key]]
          end
        end
      end

      def string?(key)
        key[0] == '"' && key[-1] == '"'
      end

      def symbol?(key)
        key[0] == ':'
      end

      def json_syntax(key, value, width)
        formatted_key = if symbol?(key)
                          # Symbols should have a colon we need to remove
                          # Strings should have surrounding double quotes we need to remove
                          # symbol?(key) ? key[1..-1] : key[1..-2]
                          key[1..-1].to_json
                        elsif string?(key)
                          key
                        elsif key.respond_to?(:to_json)
                          key.to_json
                        else
                          key
                        end

        formatted_value = json_awesome(value)

        "#{align(formatted_key, width)}#{colorize(': ', :hash)}#{formatted_value}"
      end

      def ruby19_syntax(key, value, width)
        return pre_ruby19_syntax(key, value, width) unless symbol?(key)

        "#{align(key[1..-1], width - 1)}#{colorize(': ', :hash)}#{inspector.awesome(value)}"
      end

      def pre_ruby19_syntax(key, value, width)
        "#{align(key, width)}#{colorize(' => ', :hash)}#{inspector.awesome(value)}"
      end

      def plain_single_line
        plain = options[:plain]
        multiline = options[:multiline]
        options[:plain] = true
        options[:multiline] = false
        yield
      ensure
        options[:plain] = plain
        options[:multiline] = multiline
      end
    end
  end
end
