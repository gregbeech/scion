require 'xenon/quoted_string'
require 'xenon/parsers/basic_rules'

module Xenon
  module Parsers

    module HeaderRules
      include Parslet, BasicRules

      # http://tools.ietf.org/html/rfc7230#section-3.2.6
      rule(:list_sep) { str(',') >> sp? }
      rule(:param_sep) { str(';') >> sp? }
      rule(:obs_text) { match(/[\u0080-\u00ff]/)}
      rule(:qdtext) { htab | sp | match(/[\u0021\u0023-\u005b\u005d-\u007e]/) | obs_text }
      rule(:quoted_pair) { str('\\') >> (htab | sp | vchar | obs_text) }
      rule(:quoted_string) { (dquote >> (qdtext | quoted_pair).repeat >> dquote).as(:quoted_string) }
      rule(:ctext) { htab | sp | match(/[\u0021-\u0027\u002a-\u005b\u005d-\u007e]/) | obs_text }
      rule(:comment) { (str('(') >> (ctext | quoted_pair | comment).repeat >> str(')')).as(:comment) }

      # http://tools.ietf.org/html/rfc7231#section-5.3.1
      rule(:weight_value) { (digit >> (str('.') >> digit.repeat(0, 3)).maybe).as(:q) }
      rule(:weight) { param_sep >> str('q') >> sp? >> str('=') >> sp? >> weight_value >> sp? }
    end

    module AuthHeaderRules
      include Parslet, HeaderRules

      rule(:token68) { ((alpha | digit | match(/[\-\._~\+\/]/)) >> str('=').repeat).repeat(1).as(:token) }
      rule(:auth_scheme) { token.as(:auth_scheme) }
      rule(:name) { token.as(:name) }
      rule(:value) { token.as(:value) }
      rule(:auth_param) { (name >> bws >> str('=') >> bws >> (token | quoted_string).as(:value)).as(:auth_param) }
      rule(:auth_params) { (auth_param.maybe >> (ows >> comma >> ows >> auth_param).repeat).as(:auth_params) }
    end

    module ETagHeaderRules
      include Parslet, HeaderRules

      # http://tools.ietf.org/html/rfc7232#section-2.3
      rule(:wildcard) { str('*').as(:wildcard) }
      rule(:weak) { str('W/').as(:weak) }
      rule(:etagc) { str('!') | match(/[\u0023-\u007e#-~]/) | obs_text }
      rule(:opaque_tag) { dquote >> etagc.repeat.as(:opaque_tag) >> dquote }
      rule(:etag) { (weak.maybe >> opaque_tag).as(:etag) }
    end

    class HeaderTransform < BasicTransform
      using QuotedString

      rule(quoted_string: simple(:qs)) { qs.unquote }
      rule(comment: simple(:c)) { c.uncomment }
    end

    class ETagHeaderTransform < HeaderTransform
      rule(etag: { opaque_tag: simple(:t), weak: simple(:w) }) { Xenon::ETag.new(t, weak: true) }
      rule(etag: { opaque_tag: simple(:t) }) { Xenon::ETag.new(t) }
    end

  end
end