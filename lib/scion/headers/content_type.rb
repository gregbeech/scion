require 'scion/headers'
require 'scion/parsers'

module Scion
  class Headers
    # http://tools.ietf.org/html/rfc7231#section-3.1.1.5
    class ContentType < Header 'Content-Type'
      attr_reader :content_type

      def initialize(content_type)
        @content_type = content_type
      end

      def self.parse(s)
        ContentType.new(Scion::ContentType.parse(s))
      end

      def to_s
        @content_type.to_s
      end
    end
  end
end