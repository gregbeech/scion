require 'parslet'

module Scion
  module Parsers

    class MediaTypeParser < Parslet::Parser
      rule(:space?) { match('\s').repeat(1).maybe }

      %w(application audio image message model multipart text video).each do |t|
        rule(t.to_sym) { str(t) }
      end
      rule(:type) { (application | audio | image | message | model | multipart | text | video).as(:type) }
      rule(:slash) { str('/') }
      rule(:subtype) { match('[a-zA-Z0-9\.\-\+]').repeat(1).as(:subtype) >> space? }

      rule(:semicolon) { str(';') >> space? }
      rule(:name) { match('[^;=\s]').repeat(1).as(:name) >> space? }
      rule(:equals) { str('=') >> space? }
      rule(:value) { match('[^;\s]').repeat(1).as(:value) >> space? }
      rule(:param) { semicolon >> name >> (equals >> value).maybe >> space? }
      rule(:params) { param.repeat(0).as(:params) }

      rule(:media_type) { type >> slash >> subtype >> params }
      root(:media_type)
    end

    class MediaRangeParser < MediaTypeParser
      rule(:wildcard) { str('*') }
      rule(:wild_media_range) { wildcard.as(:type) >> slash >> wildcard.as(:subtype) >> params }
      rule(:root_media_range) { type >> slash >> (wildcard.as(:subtype) | subtype) >> params }
      
      rule(:media_range) { wild_media_range | root_media_range }
      root(:media_range)
    end

    class MediaTypeTransform < Parslet::Transform
      rule(name: simple(:n), value: simple(:v)) { [n.str, v.str] }
      rule(name: simple(:n)) { [n.str, nil] }
      rule(type: simple(:t), subtype: simple(:s), params: subtree(:p)) { { type: t.str, subtype: s.str, params: Hash[p] } }
    end

  end
end