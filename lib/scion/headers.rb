require 'scion/model'

module Scion
  class Headers
    include Enumerable

    def initialize
      @hash = {}
    end

    def initialize_dup(other)
      super
      @hash = @hash.dup
    end

    def freeze
      @hash.freeze
      super
    end

    def each(&block)
      @hash.values.each(&block)
    end

    def set!(header)
      @hash[header.name] = header
      self
    end

    def add!(header)
      existing = @hash[header.name]
      if existing
        if existing.respond_to?(:merge)
          set!(existing.merge(header))
        else
          raise "Unmergeable header '#{header.name}' already exists"
        end
      else
        set!(header)
      end
      self
    end

    %i(set add).each do |name|
      define_method name do |header|
        dup.send("#{name}!", header)
      end
    end

    alias_method :<<, :add!

    #--------------------------------------------------------------------------

    class << self
      def register(klass)
        (@registered ||= {})[klass.const_get(:NAME)] = klass
      end

      def header_class(name)
        @registered[name]
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

    #--------------------------------------------------------------------------

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

      def initialize(*media_ranges)
        @media_ranges = media_ranges.sort.reverse!
      end

      def merge(other)
        Accept.new(*(@media_ranges + other.media_ranges))
      end

      def self.parse(s)
        Accept.new(*s.split(/\s*,\s*/).map { |v| MediaRange.parse(v) })
      end

      def to_s
        @media_ranges.map(&:to_s).join(', ')
      end
    end

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
