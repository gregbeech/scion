require 'scion/charset'
require 'scion/parsers/media_type'

module Scion
  module Parsers

    # http://tools.ietf.org/html/rfc7231#section-5.3.2
    class AcceptHeader < Parslet::Parser
      include MediaTypeRules

      rule(:comma) { str(',') >> sp? }

      rule(:accept) { (media_range >> (comma >> sp? >> media_range).repeat).as(:accept) }
      root(:accept)
    end

    # http://tools.ietf.org/html/rfc7231#section-5.3.3
    class AcceptCharsetHeader < Parslet::Parser
      include BasicRules

      rule(:comma) { str(',') >> sp? }

      rule(:weight_value) { (digit >> (str('.') >> digit.repeat(0, 3)).maybe).as(:q) }
      rule(:weight) { str(';') >> sp? >> str('q') >> sp? >> str('=') >> sp? >> weight_value >> sp? }

      rule(:charset) { token.as(:charset) }
      rule(:wildcard) { str('*') }
      rule(:charset_range) { (charset | wildcard.as(:charset)) >> sp? >> weight.maybe }

      rule(:accept_charset) { (charset_range >> (comma >> sp? >> charset_range).repeat).as(:accept_charset) }
      root(:accept_charset)
    end

    class AcceptCharsetHeaderTransform < Parslet::Transform
      rule(charset: simple(:c), q: simple(:q)) { ::Scion::CharsetRange.new(::Scion::Charset.new(c.str), q.str) }
      rule(charset: simple(:c)) { ::Scion::CharsetRange.new(::Scion::Charset.new(c.str)) }
      rule(accept_charset: sequence(:cr)) { ::Scion::Headers::AcceptCharset.new(*cr) }
    end

  end
end