require 'ipaddr'
require 'xenon/parsers/basic_rules'

module Xenon
  module Parsers

    # http://tools.ietf.org/html/rfc3986
    module UriRules
      include Parslet, BasicRules

      # unreserved    = ALPHA / DIGIT / "-" / "." / "_" / "~"
      # reserved      = gen-delims / sub-delims
      # gen-delims    = ":" / "/" / "?" / "#" / "[" / "]" / "@"
      # sub-delims    = "!" / "$" / "&" / "'" / "(" / ")"
      #                / "*" / "+" / "," / ";" / "="
      rule(:unreserved) { alpha | digit | match(/[\-\._~]/) }
      rule(:sub_delims) { match(/!\$&'\(\)\*\+,;=/) }

      # pct-encoded   = "%" HEXDIG HEXDIG
      rule(:pct_encoded) { str('%') >> hexdig >> hexdig }

      # reg-name      = *( unreserved / pct-encoded / sub-delims )
      rule(:reg_name) { unreserved | pct_encoded | sub_delims }

      # dec-octet     = DIGIT                 ; 0-9
      #               / %x31-39 DIGIT         ; 10-99
      #               / "1" 2DIGIT            ; 100-199
      #               / "2" %x30-34 DIGIT     ; 200-249
      #               / "25" %x30-35          ; 250-255
      rule(:dec_octet) { 
        str('25') >> match(/[\u0030-\u0035]/) |
        str('2') >> match(/[\u0030-\u0034]/) >> digit |
        str('1') >> digit >> digit |
        match(/[\u0031-\u0039]/) >> digit |
        digit
      }

      # IPv4address   = dec-octet "." dec-octet "." dec-octet "." dec-octet
      rule(:ipv4_address) { (dec_octet >> (str('.') >> dec_octet).repeat(3, 3)).as(:ipv4_address) }

      # IPv6address =                      6( h16 ":" ) ls32
      #       /                       "::" 5( h16 ":" ) ls32
      #       / [               h16 ] "::" 4( h16 ":" ) ls32
      #       / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
      #       / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
      #       / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
      #       / [ *4( h16 ":" ) h16 ] "::"              ls32
      #       / [ *5( h16 ":" ) h16 ] "::"              h16
      #       / [ *6( h16 ":" ) h16 ] "::"

      # ls32        = ( h16 ":" h16 ) / IPv4address
      #             ; least-significant 32 bits of address

      # h16         = 1*4HEXDIG
      #             ; 16 bits of address represented in hexadecimal
      rule(:h16) { hexdig.repeat(1, 4) }
      rule(:ls32) { (h16 >> h16) | ipv4_address }

      rule(:ipv6_sep) { match(/:(?=[^:])/) }
      rule(:h16_sep) { h16 >> ipv6_sep }

      # rule(:ipv6_address_7) {
      #   (h16_sep.repeat(0, 5) >> h16).maybe >> str('::')                      >> h16
      # }

      rule(:ipv6_address) {
        (                                                             
                                                              h16_sep.repeat(6, 6) >> ls32 |
                                                 str('::') >> h16_sep.repeat(5, 5) >> ls32 |
                                    h16.maybe >> str('::') >> h16_sep.repeat(4, 4) >> ls32 |
          (h16_sep              >> h16).maybe >> str('::') >> h16_sep.repeat(3, 3) >> ls32 |
          (h16_sep.repeat(0, 2) >> h16).maybe >> str('::') >> h16_sep.repeat(2, 2) >> ls32 |
          (h16_sep.repeat(0, 3) >> h16).maybe >> str('::') >> h16_sep              >> ls32 |
          (h16_sep.repeat(0, 4) >> h16).maybe >> str('::')                         >> ls32 |
          (h16_sep.repeat(0, 5) >> h16).maybe >> str('::')                         >> h16  |
          (h16_sep.repeat(0, 6) >> h16).maybe >> str('::')
        ).as(:ipv6_address)
      }

      # IPvFuture  = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )
      rule(:ipvf_address) { (str('v') >> hexdig >> str('.') >> (unreserved | sub_delims | str(':')).repeat(1)).as[:ipvf_address] }

      # IP-literal = "[" ( IPv6address / IPvFuture  ) "]"
      rule(:ip_literal) { str('[') >> (ipv6_address | ipvf_address) >> str(']') }

      #host        = IP-literal / IPv4address / reg-name
      rule(:host) { (ip_literal | ipv4_address | reg_name).as(:host) }

      rule(:port) { digit.repeat(1).as(:port) }
    end

    class UriParser < Parslet::Parser
      include UriRules
    end

    class UriTransform < BasicTransform
      rule(ipv4_address: simple(:a)) { IPAddr.new(a, Socket::AF_INET) }
      rule(ipv6_address: simple(:a)) { IPAddr.new(a, Socket::AF_INET6) }

    end

  end
end