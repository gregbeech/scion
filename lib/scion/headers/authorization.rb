require 'base64'
require 'scion/headers'
require 'scion/parsers/header_rules'
require 'scion/quoted_string'

module Scion
  class BasicCredentials
    attr_reader :username, :password

    def initialize(username, password)
      @username = username
      @password = password
    end

    def token
      Base64.strict_encode64("#{@username}:#{@password}")
    end

    def self.decode(s)
      str = Base64.strict_decode64(s)
      username, password = str.split(':', 2)
      BasicCredentials.new(username, password)
    end

    def to_s
      "Basic #{token}"
    end
  end

  class GenericCredentials
    using QuotedString

    attr_reader :scheme, :token, :params

    def initialize(scheme, token: nil, params: {})
      @scheme = scheme
      @token = token
      @params = params
    end

    def to_s
      s = @scheme.dup
      s << ' ' << @token if @token
      s << ' ' << @params.map { |n, v| "#{n}=#{v.quote}" }.join(', ')
      s
    end
  end

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
      end

      def to_s
        @credentials.to_s
      end
    end
  end

  module Parsers
    class AuthorizationHeader < Parslet::Parser
      include BasicRules
      rule(:token68) { ((alpha | digit | match(/[\-\._~\+\/]/)) >> str('=').repeat).repeat(1).as(:token) }
      rule(:auth_scheme) { token.as(:auth_scheme) }
      rule(:name) { token.as(:name) }
      rule(:value) { token.as(:value) }
      rule(:auth_param) { (name >> bws >> str('=') >> bws >> (token | quoted_string).as(:value)).as(:auth_param) } 
      rule(:auth_params) { (auth_param.maybe >> (ows >> comma >> ows >> auth_param).repeat).as(:auth_params) }
      rule(:credentials) { auth_scheme >> sp >> (token68 | auth_params) }
      rule(:authorization) { credentials.as(:authorization) }
      root(:authorization)
    end

    class AuthorizationHeaderTransform < BasicTransform
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