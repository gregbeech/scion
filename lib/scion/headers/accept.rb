require 'scion/parsers/media_type'

module Scion
  class Headers
    # http://tools.ietf.org/html/rfc7231#section-5.3.2
    class Accept < Header 'Accept'
      attr_reader :media_ranges

      def initialize(*media_ranges)
        @media_ranges = media_ranges.sort_by.with_index { |mr, i| [mr, -i] }.reverse!
      end

      def merge(other)
        Accept.new(*(@media_ranges + other.media_ranges))
      end

      def self.parse(s)
        tree = Parsers::AcceptHeader.new.parse(s)
        tree = Parsers::MediaTypeTransform.new.apply(tree)
        Accept.new(*tree[:accept])
      end

      def to_s
        @media_ranges.map(&:to_s).join(', ')
      end
    end
  end

  module Parsers
    class AcceptHeader < Parslet::Parser
      include MediaTypeRules
      rule(:accept) { (media_range >> (comma >> sp? >> media_range).repeat).as(:accept) }
      root(:accept)
    end
  end
end