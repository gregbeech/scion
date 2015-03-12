require 'parslet'

module Scion
  module Parsers

    module BasicRules
      include Parslet

      rule(:space) { str(' ').repeat(1) }
      rule(:space?) { space.maybe }
    end
    
  end
end