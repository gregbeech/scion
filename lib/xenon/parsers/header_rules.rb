require 'xenon/quoted_string'
require 'xenon/parsers/basic_rules'

module Xenon
  module Parsers

    module HeaderRules
      include Parslet, BasicRules
      
      # http://tools.ietf.org/html/rfc7231#section-5.3.1
      rule(:weight_value) { (digit >> (str('.') >> digit.repeat(0, 3)).maybe).as(:q) }
      rule(:weight) { semicolon >> str('q') >> sp? >> str('=') >> sp? >> weight_value >> sp? }

      # http://tools.ietf.org/html/rfc7230#section-3.2.6
      rule(:obs_text) { match(/[\u0080-\u00ff]/)}
      rule(:qdtext) { htab | sp | match(/[\u0021\u0023-\u005b\u005d-\u007e]/) | obs_text }
      rule(:quoted_pair) { str('\\') >> (htab | sp | vchar | obs_text) }
      rule(:quoted_string) { (dquote >> (qdtext | quoted_pair).repeat >> dquote).as(:quoted_string) }

      rule(:ctext) { htab | sp | match(/[\u0021-\u0027\u002a-\u005b\u005d-\u007e]/) | obs_text }
      rule(:comment) { (str('(') >> (ctext | quoted_pair | comment).repeat >> str(')')).as(:comment) }
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

  end
end