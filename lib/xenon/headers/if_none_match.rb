require 'xenon/headers'
require 'xenon/parsers/header_rules'
require 'xenon/errors'
require 'xenon/etag'

module Xenon
  class Headers
    # http://tools.ietf.org/html/rfc7232#section-3.2
    class IfNoneMatch < ListHeader 'If-None-Match'
      def initialize(*etags)
        super(etags)
      end
      
      alias_method :etags, :values

      def self.wildcard
        new
      end

      def self.parse(s)
        tree = Parsers::IfNoneMatchHeader.new.parse(s)
        Parsers::IfNoneMatchHeaderTransform.new.apply(tree)
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
    class IfNoneMatchHeader < Parslet::Parser
      include ETagHeaderRules
      rule(:if_match) { (wildcard | (etag >> (comma >> etag).repeat)).as(:if_match) }
      root(:if_match)
    end

    class IfNoneMatchHeaderTransform < HeaderTransform
      rule(etag: { opaque_tag: simple(:t), weak: simple(:w) }) { ETag.new(t, weak: true) }
      rule(etag: { opaque_tag: simple(:t) }) { ETag.new(t) }
      rule(if_match: { wildcard: simple(:w) }) { Headers::IfNoneMatch.new }
      rule(if_match: sequence(:et)) { Headers::IfNoneMatch.new(*et) }
      rule(if_match: simple(:et)) { Headers::IfNoneMatch.new(et) }
    end
  end
end