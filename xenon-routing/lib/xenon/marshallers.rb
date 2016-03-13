require 'xenon/media_type'

module Xenon
  module Marshaller
    def content_type
      media_type.with_charset(Encoding::UTF_8)
    end

    def unmarshal?(media_type)
      media_type == self.media_type
    end

    def marshal?(media_range)
      media_range =~ media_type
    end
  end

  class JsonMarshaller
    include Marshaller

    def media_type
      MediaType::JSON
    end

    def marshal(obj)
      [obj.to_json]
    end

    def unmarshal(body, as:)
      s = body.read
      if as.nil?
        JSON.parse(s)
      elsif as.method_defined?(:from_json)
        as.new.from_json(s)
      else
        as.new(JSON.parse(s, symbolize_names: true))
      end
    end
  end

  class XmlMarshaller
    include Marshaller

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

    def marshal(obj)
      raise "#{obj.class} does not support #to_xml" unless obj.respond_to?(:to_xml)
      [obj.to_xml]
    end

    def unmarshal(body, as:)
      as.new.from_xml(body.read)
    end
  end
end