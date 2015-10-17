require 'xenon/headers'
require 'xenon/parsers/header_rules'
require 'xenon/errors'
require 'xenon/etag'

module Xenon
  class Headers
    # http://tools.ietf.org/html/rfc7232#section-3.1
    class IfMatch < ListHeader 'If-Match'
      def initialize(*etags)
        super(etags)
      end

      alias_method :etags, :values

      def self.wildcard
        new
      end

      def self.parse(s)
        tree = Parsers::IfMatchHeader.new.parse(s)
        Parsers::IfMatchHeaderTransform.new.apply(tree)
      end

      def wildcard?
        etags.empty?
      end

      def merge(other)
        raise Xenon::ProtocolError.new('Cannot merge wildcard headers') if wildcard? || other.wildcard?
        super
      end

      def to_s
        wildcard? ? '*' : super
      end
    end
  end

  module Parsers
    class IfMatchHeader < Parslet::Parser
      include ETagHeaderRules
      rule(:if_match) { (wildcard | (etag >> (list_sep >> etag).repeat)).as(:if_match) }
      root(:if_match)
    end

    class IfMatchHeaderTransform < ETagHeaderTransform
      rule(if_match: { wildcard: simple(:w) }) { Headers::IfMatch.new }
      rule(if_match: sequence(:et)) { Headers::IfMatch.new(*et) }
      rule(if_match: simple(:et)) { Headers::IfMatch.new(et) }
    end
  end
end