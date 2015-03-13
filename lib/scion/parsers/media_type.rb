require 'scion/parsers/basic_rules'

module Scion
  module Parsers

    module MediaTypeRules
      include Parslet, BasicRules

      rule(:restricted_name_first) { match(/[a-zA-Z0-9]/) }
      rule(:restricted_name_chars) { match(/[a-zA-Z0-9!#\$&\-\^_\.\+]/).repeat(0, 126) }
      rule(:restricted_name) { restricted_name_first >> restricted_name_chars }

      rule(:type) { restricted_name.as(:type) }
      rule(:slash) { str('/') }
      rule(:subtype) { restricted_name.as(:subtype) >> sp? }

      rule(:semicolon) { str(';') >> sp? }
      rule(:param_name) { restricted_name.as(:param_name) >> sp? }
      rule(:equals) { str('=') >> sp? }
      rule(:param_value) { token.as(:param_value) >> sp? } # not quite correct but probably correct enough
      rule(:param) { semicolon >> param_name >> (equals >> param_value).maybe >> sp? }
      rule(:params) { param.repeat.as(:params) }

      rule(:media_type) { (type >> slash >> subtype >> params).as(:media_type) >> sp? }

      rule(:wildcard) { str('*') }
      rule(:wild_media_range) { wildcard.as(:type) >> slash >> wildcard.as(:subtype) >> params }
      rule(:root_media_range) { type >> slash >> (wildcard.as(:subtype) | subtype) >> params }
      rule(:media_range) { (wild_media_range | root_media_range).as(:media_range) >> sp? }
    end

    class MediaType < Parslet::Parser
      include MediaTypeRules
      root(:media_type)
    end

    class MediaRange < Parslet::Parser
      include MediaTypeRules
      root(:media_range)
    end

    class MediaTypeTransform < Parslet::Transform
      rule(param_name: simple(:n), param_value: simple(:v)) { [n.str, v.str] }
      rule(param_name: simple(:n)) { [n.str, nil] }
      rule(type: simple(:t), subtype: simple(:s), params: subtree(:p)) { { type: t.str, subtype: s.str, params: Hash[p] } }
      rule(media_type: subtree(:mt)) { ::Scion::MediaType.new(mt[:type], mt[:subtype], mt[:params])}
      rule(media_range: subtree(:mr)) { ::Scion::MediaRange.new(mr[:type], mr[:subtype], mr[:params])}
    end

  end
end