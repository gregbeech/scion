require 'scion/headers'
require 'scion/parsers/header_rules'

module Scion
  class CharsetRange
    attr_reader :charset, :q

    DEFAULT_Q = 1.0

    def initialize(charset, q = DEFAULT_Q)
      @charset = charset
      @q = Float(q) || DEFAULT_Q
    end

    def <=>(other)
      @q <=> other.q
    end

    def to_s
      s = @charset.dup
      s << "; q=#{@q}" if @q != DEFAULT_Q
      s
    end
  end

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
      rule(:wildcard) { str('*').as(:charset) >> sp? }
      rule(:charset_range) { (charset | wildcard) >> weight.maybe }
      rule(:accept_charset) { (charset_range >> (comma >> charset_range).repeat).as(:accept_charset) }
      root(:accept_charset)
    end

    class AcceptCharsetHeaderTransform < Parslet::Transform
      rule(charset: simple(:c), q: simple(:q)) { CharsetRange.new(c.str, q.str) }
      rule(charset: simple(:c)) { CharsetRange.new(c.str) }
      rule(accept_charset: sequence(:cr)) { Headers::AcceptCharset.new(*cr) }
      rule(accept_charset: simple(:cr)) { Headers::AcceptCharset.new(cr) }
    end
  end
end