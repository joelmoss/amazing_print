# frozen_string_literal: true

##
# Helper module for hash_format: :json
#
module AmazingPrint
  module JSONHelper
    def json_awesome(object, is_key: false)
      return inspector.awesome(object) unless options[:hash_format] == :json

      if object.nil?
        # Color null like we do nil
        colorize(object.to_json, :nilclass)
      elsif is_key && %w[BigDecimal Float Integer].include?(object.class.name)
        # JSON keys should be a string
        inspector.awesome(object.to_s)
      elsif %w[Array BigDecimal Float Hash Integer String].include?(object.class.name) || !object.respond_to?(:to_json)
        # These objects should not be converted to strings with #to_json so we can treat them normally
        inspector.awesome(object)
      else
        # Remove surrounding quotes added by #to_json from the standard library since
        # inspector.awesome is going to add those for us for strings.
        inspector.awesome(object.to_json.gsub(/\A"/, '').gsub(/"\z/, ''))
      end
    end
  end
end
