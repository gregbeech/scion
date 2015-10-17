require 'xenon/parsers/header_rules'

module Xenon
  # An Etag, see {http://tools.ietf.org/html/rfc7232#section-2.3 RFC 7232 § 2.3}.
  class ETag
    attr_reader :tag

    # Initializes a new ETag instance.
    # @param tag [String] The opaque tag.
    # @param weak [true, false] Whether the tag is weak.
  	def initialize(tag, weak: false)
      @tag = tag
      @weak = weak
  	end

    # Parses an ETag string.
    # @param s [String] The ETag string.
    # @return [ETag] An `ETag` object.
    def self.parse(s)
      tree = Parsers::ETag.new.etag.parse(s)
      Parsers::ETagHeaderTransform.new.apply(tree)
    rescue Parslet::ParseFailed
      raise Xenon::ParseError.new("Invalid ETag (#{s}).")
    end

    # Whether the ETag is weak.
    # @return [true, false] `true` if the ETag is weak; otherwise `false`.
  	def weak?
  	  @weak
  	end

    # Whether the ETag is strong.
    # @return [true, false] `true` if the ETag is strong; otherwise `false`.
    def strong?
      !weak?
    end

    # The strong equality function, see {http://tools.ietf.org/html/rfc7232#section-2.3.2 RFC 7232 § 2.3.2}.
    # @return [true, false] `true` if the ETags are both strong and have the same tag; otherwise `false`.
    def strong_eq?(other)
      strong? && other.strong? && @tag == other.tag
    end

    # The weak equality function, see {http://tools.ietf.org/html/rfc7232#section-2.3.2 RFC 7232 § 2.3.2}.
    # @return [true, false] `true` if the ETags have the same tag; otherwise `false`.
    def weak_eq?(other)
      @tag == other.tag
    end

    # Returns a string representation of the ETag.
    # @return [String] The ETag string.
    def to_s
      strong? ? %("#{@tag}") : %(W/"#{@tag}")
    end
  end

  module Parsers
    class ETag < Parslet::Parser
      include ETagHeaderRules
    end
  end
end