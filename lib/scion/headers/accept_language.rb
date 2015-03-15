require 'scion/language'
require 'scion/headers'
require 'scion/parsers/basic_rules'
require 'scion/parsers/header_rules'

module Scion
  class Headers
    # http://tools.ietf.org/html/rfc7231#section-5.3.5
    class AcceptLanguage < ListHeader 'Accept-Language'
      def initialize(*language_ranges)
        super(language_ranges.sort_by.with_index { |mr, i| [mr, -i] }.reverse!)
      end

      alias_method :language_ranges, :values

      def self.parse(s)
        tree = Parsers::AcceptLanguageHeader.new.parse(s)
        Parsers::AcceptLanguageHeaderTransform.new.apply(tree)
      end
    end
  end

  module Parsers
    class AcceptLanguageHeader < Parslet::Parser
      include BasicRules, WeightRules
      rule(:language) { (alpha.repeat(1, 8) >> (str('-') >> alphanum.repeat(1, 8)).maybe).as(:language) >> sp? }
      rule(:wildcard) { str('*').as(:language) >> sp? }
      rule(:language_range) { (language | wildcard) >> weight.maybe }
      rule(:accept_language) { (language_range >> (comma >> language_range).repeat).as(:accept_language) }
      root(:accept_language)
    end

    class AcceptLanguageHeaderTransform < Parslet::Transform
      rule(language: simple(:e), q: simple(:q)) { LanguageRange.new(e.str, q.str) }
      rule(language: simple(:e)) { LanguageRange.new(e.str) }
      rule(accept_language: sequence(:lr)) { Headers::AcceptLanguage.new(*lr) }
      rule(accept_language: simple(:lr)) { Headers::AcceptLanguage.new(lr) }
    end
  end
end