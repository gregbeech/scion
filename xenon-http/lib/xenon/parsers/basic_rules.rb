require 'parslet'

module Xenon
  module Parsers

    # Parslet doesn't match sequence of sequences (i.e. [['foo', 'bar']]) as a sequence(:v) in transform
    # rules so this is a little wrapper class that allows smuggling an array through the matcher rules,
    # for example above would be [Tuple.new('foo', 'bar')], when no 'proper' class is required.
    class Tuple
      def initialize(*values)
        @values = values
      end

      def to_a
        @values
      end
    end

    module BasicRules
      include Parslet

      # http://tools.ietf.org/html/rfc5234#appendix-B.1
      rule(:alpha) { match(/[a-z]/i) }
      rule(:bit) { match(/[01]/) }
      rule(:char) { match(/[\u0001-\u007f]/) }
      rule(:digit) { match(/[0-9]/) }
      rule(:hexdig) { match(/[a-f0-9]/i)}
      rule(:vchar) { match(/[\u0021-\u007e]/) }
      rule(:alphanum) { alpha | digit }

      rule(:sp) { str(' ') }
      rule(:sp?) { sp.repeat }
      rule(:htab) { str("\t") }
      rule(:wsp) { sp | htab }
      rule(:lwsp) { (crlf.maybe >> wsp).repeat }

      rule(:cr) { str("\r") }
      rule(:lf) { str("\n") }
      rule(:crlf) { cr >> lf }
      rule(:dquote) { str('"') }

      # http://tools.ietf.org/html/rfc7230#section-3.2.3
      rule(:ows) { wsp.repeat }
      rule(:rws) { wsp.repeat(1) }
      rule(:bws) { wsp.repeat }

      # http://tools.ietf.org/html/rfc7230#section-3.2.6
      rule(:tchar) { alpha | digit | match(/[!#\$%&'\*\+\-\.\^_`\|~]/) }
      rule(:token) { tchar.repeat(1) }

      # http://tools.ietf.org/html/rfc7231#section-7.1.1.1
      rule(:day_name) { str('Mon') | str('Tue') | str('Wed') | str('Thu') | str('Fri') | str('Sat') | str('Sun') }
      rule(:day) { digit.repeat(2) }
      rule(:month) { (str('Jan') | str('Feb') | str('Mar') | str('Apr') | str('May') | str('Jun') | str('Jul') | str('Aug') | str('Sep') | str('Oct') | str('Nov') | str('Dec')) }
      rule(:year) { digit.repeat(4) }
      rule(:date1) { day >> sp >> month >> sp >> year }
      rule(:gmt) { str('GMT') }
      rule(:hour) { digit.repeat(2) }
      rule(:minute) { digit.repeat(2) }
      rule(:second) { digit.repeat(2) }
      rule(:time_of_day) { hour >> str(':') >> minute >> str(':') >> second }
      rule(:imf_fixdate) { day_name >> str(',') >> sp >> date1 >> sp >> time_of_day >> sp >> gmt }
      rule(:day_name_l) { str('Monday') | str('Tuesday') | str('Wednesday') | str('Thursday') | str('Friday') | str('Saturday') | str('Sunday') }
      rule(:year2) { digit.repeat(2) }
      rule(:date2) { day >> str('-') >> month >> str('-') >> year2 }
      rule(:rfc850_date) { day_name_l >> str(',') >> sp >> date2 >> sp >> time_of_day >> sp >> gmt }
      rule(:day1) { sp >> digit }
      rule(:date3) { month >> sp >> (day | day1) }
      rule(:asctime_date) { day_name >> sp >> date3 >> sp >> time_of_day >> sp >> year }
      rule(:obs_date) { rfc850_date | asctime_date }
      rule(:http_date) { (imf_fixdate | obs_date).as(:http_date) }

      # extras -- TODO: move these into header rules?
      rule(:comma) { str(',') >> sp? }
      rule(:semicolon) { str(';') >> sp? }
    end

    class BasicTransform < Parslet::Transform
      rule(simple(:v)) { v.respond_to?(:str) ? v.str : v }

      rule(quoted_string: simple(:qs)) { qs[1..-2].gsub(/\\(.)/, '\1') }
      rule(http_date: simple(:str)) { Time.httpdate(str) }
    end

  end
end