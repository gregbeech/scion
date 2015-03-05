require 'scion/model'

module Scion
  module Headers

    class Header
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end

    class Raw < Header
      attr_reader :value

      def initialize(name, value)
        super(name)
        @value = value
      end

      def to_s
        @value
      end
    end

    class Accept < Header
      attr_reader :media_ranges

      def initialize(media_ranges)
        super('Accept')
        @media_ranges = media_ranges.sort.reverse
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
