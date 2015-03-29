require 'xenon/headers'
require 'xenon/parsers/header_rules'
require 'xenon/parsers/uri'
require 'xenon/errors'
require 'xenon/protocol'

module Xenon
  class ViaProxy
    attr_reader :protocol, :host, :port, :comment

    def initialize(protocol, host, port: nil, comment: nil)
      @protocol = protocol
      @host = host
      @port = port
      @comment = comment
    end

    def to_s
      s = "#{@protocol.to_s} #{@host}"
      s << ':' << @port if @port
      s << ' (' << @comment << ')' if @comment
      s
    end
  end

  class Headers
    # http://tools.ietf.org/html/rfc7230#section-5.7.1
    class Via < ListHeader 'Via'
      def initialize(*proxies)
        super(proxies)
      end
      
      alias_method :proxies, :values

      def self.parse(s)
        tree = Parsers::ViaHeader.new.parse(s)
        tree = Parsers::UriTransform.new.apply(tree)
        tree = Parsers::ViaHeaderTransform.new.apply(tree)
        tree
      end
    end
  end

  module Parsers
    class ViaHeader < Parslet::Parser
      include HeaderRules, UriRules
      rule(:protocol_name) { token.as(:protocol_name) }
      rule(:protocol_version) { token.as(:protocol_version) }
      rule(:protocol) { ((protocol_name >> str('/')).maybe >> protocol_version).as(:protocol) }

      rule(:pseudonym) { token.as(:host) }
      rule(:received_by) { ((host >> (str(':') >> port).maybe) | pseudonym).as(:received_by) }

      rule(:via_proxy) { (protocol >> rws >> received_by).as(:via_proxy) } # TODO: Comment
      rule(:via) { (via_proxy >> (rws >> via_proxy).repeat).as(:via) }
      root(:via)
    end

    class ViaHeaderTransform < HeaderTransform
      rule(protocol_name: simple(:n), protocol_version: simple(:v)) { Protocol.new(n, v) }
      rule(protocol_version: simple(:v)) { Protocol.new(nil, v) }

      rule(via_proxy: { protocol: simple(:p), received_by: { host: simple(:h) } }) { ViaProxy.new(p, h) }
      rule(via_proxy: { protocol: simple(:p), received_by: { host: simple(:h), port: simple(:pt) } }) { ViaProxy.new(p, h, port: pt.to_i) }

      rule(via: sequence(:et)) { Headers::Via.new(*et) }
      rule(via: simple(:et)) { Headers::Via.new(et) }
    end
  end
end