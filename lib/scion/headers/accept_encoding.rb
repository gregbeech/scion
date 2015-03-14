require 'scion/content_coding'
require 'scion/headers'
require 'scion/parsers/basic_rules'
require 'scion/parsers/header_rules'

module Scion
  class Headers
    # http://tools.ietf.org/html/rfc7231#section-5.3.4
    class AcceptEncoding < Header 'Accept-Encoding'
      attr_reader :coding_ranges

      def initialize(*coding_ranges)
        @coding_ranges = coding_ranges.sort_by.with_index { |mr, i| [mr, -i] }.reverse!
      end

      def merge(other)
        AcceptEncoding.new(*(@coding_ranges + other.coding_ranges))
      end

      def self.parse(s)
        tree = Parsers::AcceptEncodingHeader.new.parse(s)
        Parsers::AcceptEncodingHeaderTransform.new.apply(tree)
      end

      def to_s
        @coding_ranges.map(&:to_s).join(', ')
      end
    end
  end

  module Parsers
    class AcceptEncodingHeader < Parslet::Parser
      include BasicRules, WeightRules
      %w(identity compress x-compress deflate gzip x-gzip).each do |c|
        rule(c.tr('-', '_').to_sym) { str(c) >> sp? }
      end
      rule(:coding) { compress | x_compress | deflate | gzip | x_gzip }
      rule(:wildcard) { str('*') >> sp? }
      rule(:coding_range) { (coding | identity | wildcard).as(:coding) >> weight.maybe }
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