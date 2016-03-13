require 'active_support/core_ext/string'

module Xenon
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

    def remove!(header)
      header = header.name if header.respond_to?(:name)
      @hash.delete(header)
      self
    end

    %i(set add remove).each do |name|
      define_method name do |header|
        dup.send("#{name}!", header)
      end
    end

    alias_method :<<, :add!

    class << self
      def register(klass)
        (@registered ||= {})[klass.const_get(:NAME)] = klass
      end

      def header_class(name)
        (@registered || {})[name]
      end

      def Header(name)
        klass = Class.new do
          def name
            self.class.const_get(:NAME)
          end

          def self.inherited(base)
            Headers.register(base)
          end

          def self.parse(s)
            base_name = name.demodulize
            tree = Xenon::Parsers.const_get("#{base_name}Header").new.parse(s) # TODO: HeaderParser would be better
            Xenon::Parsers.const_get("#{base_name}HeaderTransform").new.apply(tree)
          rescue Parslet::ParseFailed
            raise Xenon::ParseError
          end
        end
        Headers.const_set("#{name.tr('-', '_').classify}Header", klass)
        klass.const_set(:NAME, name)
        klass
      end

      def ListHeader(name)
        klass = Header(name)
        klass.class_eval do
          attr_reader :values

          def initialize(values)
            @values = values
          end

          def merge(other)
            self.class.new(*(@values + other.values))
          end

          def to_s
            @values.map(&:to_s).join(', ')
          end
        end
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
  end
end

Dir[File.join(__dir__, 'headers', '*.rb')].each { |f| require f }
