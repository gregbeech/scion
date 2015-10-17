require 'xenon/headers'
require 'xenon/parsers/header_rules'

module Xenon
  class Product
    attr_reader :name, :version, :comment

    def initialize(name, version = nil, comment = nil)
      @name = name
      @version = version
      @comment = comment
    end

    def to_s
      s = ''
      s << @name if @name
      s << '/' << @version if @version
      if @comment
        s << ' ' unless s.empty?
        s << '(' << @comment << ')'
      end
      s
    end
  end

  class Headers
    # http://tools.ietf.org/html/rfc7231#section-5.5.3
    class UserAgent < Header 'User-Agent'
      attr_reader :products

      def initialize(*products)
        @products = products
      end

      def self.parse(s)
        tree = Parsers::UserAgentHeader.new.parse(s)
        Parsers::UserAgentHeaderTransform.new.apply(tree)
      end

      def to_s
        @products.map(&:to_s).join(' ')
      end
    end
  end

  module Parsers
    class UserAgentHeader < Parslet::Parser
      include HeaderRules
      rule(:product) { (token.as(:name) >> (str('/') >> token.as(:version)).maybe >> (rws >> comment.as(:comment)).maybe).as(:product) }
      rule(:product_comment) { comment.as(:product_comment) }
      rule(:user_agent) { (product >> (rws >> (product | product_comment)).repeat).as(:user_agent) }
      root(:user_agent)
    end

    class UserAgentHeaderTransform < HeaderTransform
      rule(product: { name: simple(:p), version: simple(:v), comment: simple(:c) }) { Product.new(p, v, c) }
      rule(product: { name: simple(:p), version: simple(:v) }) { Product.new(p, v) }
      rule(product: { name: simple(:p), comment: simple(:c) }) { Product.new(p, nil, c) }
      rule(product: { name: simple(:p) }) { Product.new(p) }
      rule(product_comment: simple(:c)) { Product.new(nil, nil, c) }
      rule(user_agent: sequence(:p)) { Headers::UserAgent.new(*p) }
      rule(user_agent: simple(:p)) { Headers::UserAgent.new(p) }
    end
  end
end