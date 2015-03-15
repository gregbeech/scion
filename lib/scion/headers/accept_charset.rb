require 'scion/charset'
require 'scion/headers'
require 'scion/parsers/basic_rules'
require 'scion/parsers/header_rules'

module Scion
  class Headers
    # http://tools.ietf.org/html/rfc7231#section-5.3.3
    class AcceptCharset < ListHeader 'Accept-Charset'
      def initialize(*charset_ranges)
        super(charset_ranges.sort_by.with_index { |mr, i| [mr, -i] }.reverse!)
      end

      alias_method :charset_ranges, :values

      def self.parse(s)
        tree = Parsers::AcceptCharsetHeader.new.parse(s)
        Parsers::AcceptCharsetHeaderTransform.new.apply(tree)
      end
    end
  end

  module Parsers
    class AcceptCharsetHeader < Parslet::Parser
      include BasicRules, WeightRules
      rule(:charset) { token.as(:charset) >> sp? }
      rule(:wildcard) { str('*') >> sp? }
      rule(:charset_range) { (charset | wildcard.as(:charset)) >> weight.maybe }
      rule(:accept_charset) { (charset_range >> (comma >> charset_range).repeat).as(:accept_charset) }
      root(:accept_charset)
    end

    class AcceptCharsetHeaderTransform < Parslet::Transform
      rule(charset: simple(:c), q: simple(:q)) { CharsetRange.new(c.str, q.str) }
      rule(charset: simple(:c)) { CharsetRange.new(c.str) }
      rule(accept_charset: sequence(:cr)) { Headers::AcceptCharset.new(*cr) }
    end
  end
end