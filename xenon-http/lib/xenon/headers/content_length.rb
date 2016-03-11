require 'xenon/headers'
require 'xenon/media_type'

module Xenon
  class Headers
    # https://tools.ietf.org/html/rfc7230#section-3.3.2
    class ContentLength < Header 'Content-Length'
      attr_reader :content_length

      def initialize(content_length)
        @content_length = content_length
      end

      def self.parse(s)
        Integer(s)
      end

      def to_s
        @content_length.to_s
      end
    end
  end
end