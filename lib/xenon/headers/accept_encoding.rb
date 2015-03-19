require 'xenon/headers'
require 'xenon/parsers/header_rules'

module Xenon
  class ContentCodingRange
    attr_reader :coding, :q

    DEFAULT_Q = 1.0

    def initialize(coding, q = DEFAULT_Q)
      @coding = coding
      @q = Float(q) || DEFAULT_Q
    end

    def <=>(other)
      @q <=> other.q
    end

    def to_s
      s = @coding.dup
      s << "; q=#{@q}" if @q != DEFAULT_Q
      s
    end
  end

  class Headers
    # http://tools.ietf.org/html/rfc7231#section-5.3.4
    class AcceptEncoding < ListHeader 'Accept-Encoding'
      def initialize(*coding_ranges)
        super(coding_ranges.sort_by.with_index { |mr, i| [mr, -i] }.reverse!)
      end

      alias_method :coding_ranges, :values

      def self.parse(s)
        tree = Parsers::AcceptEncodingHeader.new.parse(s)
        Parsers::AcceptEncodingHeaderTransform.new.apply(tree)
      end
    end
  end

  module Parsers
    class AcceptEncodingHeader < Parslet::Parser
      include HeaderRules
      %w(identity compress x-compress deflate gzip x-gzip).each do |c|
        rule(c.tr('-', '_').to_sym) { str(c).as(:coding) >> sp? }
      end
      rule(:coding) { compress | x_compress | deflate | gzip | x_gzip }
      rule(:wildcard) { str('*').as(:coding) >> sp? }
      rule(:coding_range) { (coding | identity | wildcard) >> weight.maybe }
      rule(:accept_encoding) { (coding_range >> (comma >> coding_range).repeat).maybe.as(:accept_encoding) }
      root(:accept_encoding)
    end

    class AcceptEncodingHeaderTransform < Parslet::Transform
      rule(coding: simple(:c), q: simple(:q)) { ContentCodingRange.new(c.str, q.str) }
      rule(coding: simple(:c)) { ContentCodingRange.new(c.str) }
      rule(accept_encoding: sequence(:er)) { Headers::AcceptEncoding.new(*er) }
      rule(accept_encoding: simple(:cc)) { Headers::AcceptEncoding.new(cc) }
      rule(accept_encoding: nil) { Headers::AcceptEncoding.new }
    end
  end
end