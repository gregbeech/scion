require 'json'
require 'rack'
require 'active_support/core_ext/string'
require 'scion/headers'
require 'scion/routing'

module Scion

  class Rejection
    ACCEPT = 'ACCEPT'
    HEADER = 'HEADER'
    METHOD = 'METHOD'

    attr_reader :reason, :info

    def initialize(reason, info = {})
      @reason = reason
      @info = info
    end

    def [](name)
      @info[name]
    end
  end

  class Request
    attr_accessor :unmatched_path

    def initialize(rack_req)
      @rack_req = rack_req
      @unmatched_path = rack_req.path
      freeze
    end

    def request_method
      @rack_req.request_method.downcase.to_sym
    end

    def form_hash
      @rack_req.POST
    end

    def query_hash
      @rack_req.GET
    end

    def header(name)
      snake_name = name.to_s.tr('-', '_')
      value = @rack_req.env['HTTP_' + snake_name.upcase]
      return nil if value.nil?

      klass = Scion::Headers.header_class(name)
      klass ? klass.parse(value) : Scion::Headers::Raw.new(name, value)
    end

    def copy(changes = {})
      r = dup
      changes.each { |k, v| r.instance_variable_set("@#{k}", v) }
      r.freeze
    end

    def freeze
      @unmatched_path.freeze
      super
    end
  end

  class Response
    attr_reader :status, :headers, :body

    def initialize
      @headers = Headers.new
      @complete = false
      freeze
    end

    def complete?
      @complete
    end

    def copy(changes = {})
      r = dup
      changes.each { |k, v| r.instance_variable_set("@#{k}", v) }
      r.freeze
    end

    def freeze
      @headers.freeze
      @body.freeze
      super
    end

    def self.error(status, developer_message = nil)
      body = { 
        status: status, 
        developer_message: developer_message || Rack::Utils::HTTP_STATUS_CODES[status]
      }
      Response.new.copy(complete: true, status: status, body: body)
    end
  end

  class Context
    attr_accessor :request, :response, :rejections

    def initialize(request, response)
      @request = request
      @response = response
      @rejections = []
    end

    def branch
      original_request = @request
      original_response = @response
      yield
    ensure
      @request = original_request
      @response = original_response unless @response.complete?
    end
  end

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

  class Api
    include Scion::Routing::Directives

    DEFAULT_MARSHALLERS = [JsonMarshaller.new]

    class << self
      def marshallers(*marshallers)
        @marshallers = marshallers unless marshallers.nil? || marshallers.empty?
        (@marshallers.nil? || @marshallers.empty?) ? DEFAULT_MARSHALLERS : @marshallers
      end

      def select_marshaller(media_ranges)
        puts "@marshallers = #{@marshallers}"
        media_ranges.lazy.map { |mr| marshallers.find { |m| m.marshal_to?(mr) } }.find { |m| m }
      end
    end

    attr_reader :context

    def route
      raise NotImplementedError.new
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @context = Context.new(Request.new(Rack::Request.new(env)), Response.new)

      accept = @context.request.header('Accept')
      marshaller = accept ? self.class.select_marshaller(accept.media_ranges) : self.class.marshallers.first
      begin
        if marshaller.nil?
          @context.rejections << Rejection.new(Rejection::ACCEPT, { supported: self.class.marshallers.map(&:media_type) })
        else
          catch (:complete) { route }
        end
        @context.response = handle_rejections(@context.rejections) unless @context.response.complete?
      rescue => e
        @context.response = handle_error(e)
      end
      @context.response = Response.error(501, 'The response was not completed') unless @context.response.complete?

      marshaller ||= self.class.marshallers.first
      resp = @context.response.copy(
        headers: @context.response.headers.set(Headers::ContentType.new(marshaller.content_type)),
        body: marshaller.marshal(@context.response.body))
      [resp.status, resp.headers.map { |h| [h.name, h.to_s] }.to_h, resp.body]
    end

    def handle_error(e)
      puts "handle_error: #{e}"
      @context.response = Response.error(500)
    end

    def handle_rejections(rejections)
      puts "handle_rejections: #{rejections}"
      if rejections.empty?
        Response.error(404)
      else
        rejection = rejections.first
        case rejection.reason
        when Rejection::ACCEPT
          Response.error(406, "Supported media types: #{rejection[:supported].join(", ")}")
        when Rejection::HEADER
          Response.error(400, "Missing required header: #{rejection[:required]}")
        when Rejection::METHOD
          supported = rejections.take_while { |r| r.reason == Rejection::METHOD }.map { |r| r[:supported].upcase }
          Response.error(405, "Supported methods: #{supported.join(", ")}")
        else 
          Response.error(500)
        end
      end
    end

  end

end
