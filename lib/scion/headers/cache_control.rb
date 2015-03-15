require 'scion/headers'
require 'scion/parsers/basic_rules'
require 'scion/parsers/header_rules'

module Scion
  class Headers

    class CacheDirective
      attr_reader :name, :value

      def initialize(name, value = nil)
        @name = name
        @value = value
      end

      def to_s
        s = @name.dup
        s << '=' << quote(@value) if @value
        s
      end

      private

      # TODO: Extract this out to somewhere more useful
      def quote(s)
        qs = s.gsub(/([\\"])/, '\\\\\1')
        s == qs ? s : %{"#{qs}"}
      end
    end

    # http://tools.ietf.org/html/rfc7234#section-5.2
    class CacheControl < ListHeader 'Cache-Control'
      def initialize(*directives)
        super(directives)
      end
      
      alias_method :directives, :values

      def self.parse(s)
        tree = Parsers::CacheControlHeader.new.parse(s)
        Parsers::CacheControlHeaderTransform.new.apply(tree)
      end
    end
  end

  module Parsers
    class CacheControlHeader < Parslet::Parser
      include BasicRules
      rule(:name) { token.as(:name) }
      rule(:value) { str('=') >> (token | quoted_string).as(:value) }
      rule(:directive) { (name >> value.maybe).as(:directive) >> sp? }
      rule(:cache_control) { (directive >> (comma >> directive).repeat).as(:cache_control) }
      root(:cache_control)
    end

    class CacheControlHeaderTransform < BasicTransform
      rule(directive: { name: simple(:n), value: simple(:v) }) { Headers::CacheDirective.new(n, v) }
      rule(directive: { name: simple(:n) }) { Headers::CacheDirective.new(n) }
      rule(cache_control: sequence(:d)) { Headers::CacheControl.new(*d) }
      rule(cache_control: simple(:d)) { Headers::CacheControl.new(d) }
    end
  end
end