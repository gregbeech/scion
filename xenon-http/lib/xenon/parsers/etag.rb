require 'xenon/parsers/header_rules'

module Xenon
  module Parsers
    class ETag < Parslet::Parser
      include ETagHeaderRules
    end
  end
end
