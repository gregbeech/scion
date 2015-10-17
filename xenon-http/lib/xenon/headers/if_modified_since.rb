require 'xenon/headers'

module Xenon
  class Headers
    # http://tools.ietf.org/html/rfc7232#section-3.3
    class IfModifiedSince < Header 'If-Modified-Since'
      attr_reader :date

      def initialize(date)
        @date = date
      end

      def self.parse(s)
        new(Time.httpdate(s))
      end

      def to_s
        @date.httpdate
      end
    end
  end
end