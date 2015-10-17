require 'xenon/headers'
require 'xenon/parsers/header_rules'
require 'xenon/errors'
require 'xenon/etag'

module Xenon
  class Headers
    # http://tools.ietf.org/html/rfc7233#section-3.2
    class IfRange < Header 'If-Range'
      attr_reader :date, :etag

      def initialize(value)
        case value
        when Time, DateTime, Date then @date = value
        when ETag then @etag = value
        when String then @etag = ETag.parse(value)
        else raise ArgumentError, 'Value must be a time or an etag.'
        end

        raise ProtocolError, 'If-Range headers must use strong ETags.' if @etag && @etag.weak?
      end

      def self.parse(s)
        tree = Parsers::IfRangeHeader.new.parse(s)
        Parsers::IfRangeHeaderTransform.new.apply(tree)
      end

      def to_s
        @etag ? @etag.to_s : @date.httpdate
      end
    end
  end

  module Parsers
    class IfRangeHeader < Parslet::Parser
      include ETagHeaderRules
      rule(:if_range) { (etag | http_date).as(:if_range) }
      root(:if_range)
    end

    class IfRangeHeaderTransform < ETagHeaderTransform
      rule(if_range: simple(:v)) { Headers::IfRange.new(v) }
    end
  end
end