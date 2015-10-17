require 'active_support/core_ext/hash/indifferent_access'
require 'forwardable'
require 'xenon/headers'
require 'xenon/parsers/header_rules'
require 'xenon/quoted_string'

module Xenon
  class Headers
    class Challenge
      extend Forwardable
      using QuotedString

      attr_reader :auth_scheme
      def_delegators :@params, :key?, :include?, :[]

      def initialize(auth_scheme, params = {})
        @auth_scheme = auth_scheme
        @params = params.with_indifferent_access
      end

      def method_missing(name, *args, &block)
        name = name.to_sym
        @params.key?(name) ? @params[name] : super
      end

      def respond_to_missing?(name, include_all)
        @params.key?(name.to_sym) || super
      end

      def to_s
        param_string = @params.map { |k, v| "#{k}=#{v.quote}"}.join(', ')
        "#{@auth_scheme} #{param_string}"
      end
    end

    # https://tools.ietf.org/html/rfc7235#section-4.1
    class WWWAuthenticate < ListHeader 'WWW-Authenticate'
      def initialize(*challenges)
        super(challenges)
      end

      alias_method :challenges, :values

      def self.parse(s)
        tree = Parsers::WWWAuthenticateHeader.new.parse(s)
        Parsers::WWWAuthenticateHeaderTransform.new.apply(tree)
      end

      def to_s
        challenges.map(&:to_s).join(', ')
      end
    end
  end

  module Parsers
    class WWWAuthenticateHeader < Parslet::Parser
      include AuthHeaderRules
      rule(:challenge) { (auth_scheme >> sp >> (auth_params | token68)).as(:challenge) }
      rule(:www_authenticate) { (challenge >> (comma >> challenge).repeat).as(:www_authenticate) }
      root(:www_authenticate)
    end

    class WWWAuthenticateHeaderTransform < HeaderTransform
      rule(auth_param: { name: simple(:n), value: simple(:v) }) { Tuple.new(n, v) }
      rule(challenge: { auth_scheme: simple(:s), auth_params: simple(:p) }) { Headers::Challenge.new(s, Hash[*p.to_a]) }
      rule(challenge: { auth_scheme: simple(:s), auth_params: sequence(:p) }) { Headers::Challenge.new(s, Hash[p.map(&:to_a)]) }
      rule(www_authenticate: simple(:c)) { Headers::WWWAuthenticate.new(c) }
      rule(www_authenticate: sequence(:c)) { Headers::WWWAuthenticate.new(*c) }
    end
  end
end