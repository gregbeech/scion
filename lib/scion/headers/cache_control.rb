require 'scion/headers'
require 'scion/parsers/header_rules'
require 'scion/quoted_string'

module Scion
  class CacheDirective
    using QuotedString

    attr_reader :name, :value

    def initialize(name, value = nil)
      @name = name
      @value = value
    end

    def to_s
      s = @name.dup
      s << '=' << @value.quote if @value
      s
    end
  end

  class Headers
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
      rule(directive: { name: simple(:n), value: simple(:v) }) { CacheDirective.new(n, v) }
      rule(directive: { name: simple(:n) }) { CacheDirective.new(n) }
      rule(cache_control: sequence(:d)) { Headers::CacheControl.new(*d) }
      rule(cache_control: simple(:d)) { Headers::CacheControl.new(d) }
    end
  end
end