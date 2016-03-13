require 'xenon/headers'
require 'xenon/parsers/header_rules'

module Xenon
  class Headers
    # https://tools.ietf.org/html/rfc6265#section-4.2.1
    class Cookie < Header 'Cookie'
      attr_reader :cookies

      def initialize(cookies = {})
        @cookies = cookies.freeze
      end
    end
  end

  module Parsers
    class CookieHeader < Parslet::Parser
      include HeaderRules
      rule(:cookie_octet) { str("\u0021") | match(/[\u0023-\u002b]/) | match(/[\u002d-\u003a]/) | match(/[\u003c-\u005b]/) | match(/[\u005d-\u007e]/) }
      rule(:cookie_name) { token.as(:cookie_name) }
      rule(:cookie_value) { cookie_octet.repeat.as(:cookie_value) | (dquote >> cookie_octet.repeat.as(:cookie_value) >> dquote) }
      rule(:cookie_pair) { (cookie_name >> str('=') >> cookie_value).as(:cookie_pair) }
      rule(:cookie_string) { cookie_pair >> (semicolon >> cookie_pair).repeat }
      rule(:cookie) { ows >> cookie_string.as(:cookie) >> ows }
      root(:cookie)
    end

    class CookieHeaderTransform < HeaderTransform
      rule(cookie_pair: { cookie_name: simple(:n), cookie_value: simple(:v) }) { Tuple.new(n, v) }
      rule(cookie: sequence(:c)) { Headers::Cookie.new(Hash[c.map(&:to_a)]) }
      rule(cookie: simple(:c)) { Headers::Cookie.new(c.first => c.last) }
    end
  end
end
