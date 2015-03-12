require 'scion/parsers/media_type'

module Scion
  module Parsers

    class AcceptHeader < Parslet::Parser
      include MediaRangeRules

      rule(:comma) { str(',') >> space? }

      rule(:accept) { (media_range >> (comma >> media_range).repeat).as(:accept) }
      root(:accept)
    end

  end
end