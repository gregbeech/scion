require 'base64'
require 'xenon/auth'
require 'xenon/headers'
require 'xenon/parsers/header_rules'

module Xenon
  class Headers
    # http://tools.ietf.org/html/rfc7235#section-4.2
    class Authorization < Header 'Authorization'
      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      def self.parse(s)
        tree = Parsers::AuthorizationHeader.new.parse(s)
        Parsers::AuthorizationHeaderTransform.new.apply(tree)
      rescue Parslet::ParseFailed
        raise Xenon::ParseError.new("Invalid Authorization header (#{s}).")
      end

      def to_s
        @credentials.to_s
      end
    end
  end

  module Parsers
    class AuthorizationHeader < Parslet::Parser
      include AuthHeaderRules
      rule(:credentials) { auth_scheme >> sp >> (token68 | auth_params) }
      rule(:authorization) { credentials.as(:authorization) }
      root(:authorization)
    end

    class AuthorizationHeaderTransform < HeaderTransform
      rule(auth_param: { name: simple(:n), value: simple(:v) }) { [n, v] }
      rule(auth_params: subtree(:x)) { { foo: x } }
      rule(auth_scheme: simple(:s), token: simple(:t)) {
        case s
        when 'Basic' then BasicCredentials.decode(t)
        else GenericCredentials.new(s, token: t)
        end
      }
      rule(auth_scheme: simple(:s), auth_params: subtree(:p)) { GenericCredentials.new(s, params: Hash[p]) }
      rule(authorization: simple(:c)) { Headers::Authorization.new(c) }
    end
  end
end