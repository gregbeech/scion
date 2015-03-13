require 'scion/charset'
require 'scion/headers'
require 'scion/parsers/basic_rules'

module Scion
  class Headers
    # http://tools.ietf.org/html/rfc7231#section-5.3.3
    class AcceptCharset < Header 'Accept-Charset'
      attr_reader :charset_ranges

      def initialize(*charset_ranges)
        @charset_ranges = charset_ranges.sort_by.with_index { |mr, i| [mr, -i] }.reverse!
      end

      def merge(other)
        AcceptCharset.new(*(@charset_ranges + other.charset_ranges))
      end

      def self.parse(s)
        tree = Parsers::AcceptCharsetHeader.new.parse(s)
        Parsers::AcceptCharsetHeaderTransform.new.apply(tree)
      end

      def to_s
        @charset_ranges.map(&:to_s).join(', ')
      end
    end
  end

  module Parsers
    class AcceptCharsetHeader < Parslet::Parser
      include BasicRules

      rule(:weight_value) { (digit >> (str('.') >> digit.repeat(0, 3)).maybe).as(:q) }
      rule(:weight) { str(';') >> sp? >> str('q') >> sp? >> str('=') >> sp? >> weight_value >> sp? }

      rule(:charset) { token.as(:charset) }
      rule(:wildcard) { str('*') }
      rule(:charset_range) { (charset | wildcard.as(:charset)) >> sp? >> weight.maybe }

      rule(:accept_charset) { (charset_range >> (comma >> sp? >> charset_range).repeat).as(:accept_charset) }
      root(:accept_charset)
    end

    class AcceptCharsetHeaderTransform < Parslet::Transform
      rule(charset: simple(:c), q: simple(:q)) { CharsetRange.new(c.str, q.str) }
      rule(charset: simple(:c)) { CharsetRange.new(c.str) }
      rule(accept_charset: sequence(:cr)) { Headers::AcceptCharset.new(*cr) }
    end
  end
end