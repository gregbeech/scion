require 'xenon/media_type'

module Xenon
  class JsonMarshaller
    def media_type
      MediaType::JSON
    end

    def content_type
      media_type.with_charset(Encoding::UTF_8)
    end

    def marshal_to?(media_range)
      media_range =~ media_type
    end

    def marshal(obj)
      [obj.to_json]
    end
  end

  class XmlMarshaller
    def initialize
      gem 'builder'
      require 'active_support/core_ext/array/conversions'
      require 'active_support/core_ext/hash/conversions'
    rescue Gem::LoadError
      raise 'Install the "builder" gem to enable XML.'
    end

    def media_type
      MediaType::XML
    end

    def content_type
      media_type.with_charset(Encoding::UTF_8)
    end

    def marshal_to?(media_range)
      media_range =~ media_type
    end

    def marshal(obj)
      raise "#{obj.class} does not support #to_xml" unless obj.respond_to?(:to_xml)
      [obj.to_xml]
    end
  end
end