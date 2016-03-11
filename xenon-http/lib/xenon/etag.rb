require 'xenon/parsers/etag'

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
      freeze
    end

    # Prevents further modifications to the ETag.
    # @return [ETag] This method returns self.
    def freeze
      @tag.freeze
      super
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

    # An equality function that checks the ETags have the same strength and tag.
    # @return [true, false] `true` if the ETags have the same strength and tag; otherwise `false`.
    def ==(other)
      strong? == other.strong? && @tag == other.tag
    end
    alias_method :eql?, :==

    # A case equality function that uses {strong_eq?} or {weak_eq?} depending on whether the receiving
    # tag is strong or weak, respectively.
    # @return [true, false] `true` if the other ETag matches; otherwise `false`.
    def ===(other)
      strong? ? strong_eq?(other) : weak_eq?(other)
    end
    alias_method :=~, :===

    # Returns a hash code based on the ETag state.
    # @return [Fixnum] The ETag hash.
    def hash
      to_s.hash
    end

    # Returns a string representation of the ETag.
    # @return [String] The ETag string.
    def to_s
      strong? ? %("#{@tag}") : %(W/"#{@tag}")
    end
  end
end
