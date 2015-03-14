require 'parslet'

module Scion
  module Parsers

    # http://tools.ietf.org/html/rfc7231#section-5.3.1
    module WeightRules
      include Parslet
      rule(:weight_value) { (digit >> (str('.') >> digit.repeat(0, 3)).maybe).as(:q) }
      rule(:weight) { semicolon >> str('q') >> sp? >> str('=') >> sp? >> weight_value >> sp? }
    end

  end
end