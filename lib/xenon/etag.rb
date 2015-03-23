module Xenon
  class ETag
    attr_reader :opaque_tag

  	def initialize(opaque_tag, weak: false)
      @opaque_tag = opaque_tag
      @weak = weak
  	end

    def self.parse(s)
      weak = s.start_with?('W/')
      opaque_tag = weak ? etag[3..-2] : etag[1..-2]
      ETag.new(opaque_tag, weak: weak)
    end

  	def weak?
  	  @weak
  	end

    def strong?
      !weak?
    end

    def strong_eq?(other)
      strong? && other.strong? && @opaque_tag == other.opaque_tag
    end

    def weak_eq?(other)
      @opaque_tag == other.opaque_tag
    end

    def ==(other)
      strong? == other.strong? && @opaque_tag == other.opaque_tag
    end

    def to_s
      s = weak? ? "W/" : ""
      s << '"' << @opaque_tag << '"'
    end
  end
end