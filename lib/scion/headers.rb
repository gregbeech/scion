require 'scion/model'

module Scion
  module Headers

    class << self
      def register(klass)
        (@registered_headers ||= {})[klass.const_get(:NAME)] = klass
      end

      def header_class(name)
        @registered_headers[name]
      end

      def Header(name)
        klass = Class.new do
          def name
            self.class.const_get(:NAME)
          end

          def self.inherited(base)
            Headers.register(base)
          end
        end
        Headers.const_set("#{name.tr('-', '_').classify}Header", klass)
        klass.const_set(:NAME, name)
        klass
      end
    end

    class Raw
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end

      def to_s
        @value
      end
    end

    class Accept < Header 'Accept'
      attr_reader :media_ranges

      def initialize(media_ranges)
        @media_ranges = media_ranges.sort.reverse!
      end

      def self.parse(s)
        Accept.new(s.split(/\s*,\s*/).map { |v| MediaRange.parse(v) })
      end

      def to_s
        @media_ranges.map(&:to_s).join(', ')
      end
    end

  end
end
