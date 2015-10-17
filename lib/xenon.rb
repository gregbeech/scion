require 'json'
require 'rack'
require 'active_support/core_ext/string'
require 'xenon/headers'
require 'xenon/routing/directives'
require 'xenon/version'

module Xenon

  class Rejection
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
      @unmatched_path = rack_req.path.freeze
    end

    def request_method
      @rack_req.request_method.downcase.to_sym
    end

    def form_hash
      @form_hash ||= @rack_req.POST.with_indifferent_access.freeze
    end

    def param_hash
      puts "GET = #{@rack_req.GET.inspect}"
      @param_hash ||= @rack_req.GET.with_indifferent_access.freeze
    end

    def header(name)
      snake_name = name.to_s.tr('-', '_')
      value = @rack_req.env['HTTP_' + snake_name.upcase]
      return nil if value.nil?

      klass = Xenon::Headers.header_class(name)
      klass ? klass.parse(value) : Xenon::Headers::Raw.new(name, value)
    end

    def copy(changes = {})
      r = dup
      changes.each { |k, v| r.instance_variable_set("@#{k}", v.freeze) }
      r
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

  class API
    include Xenon::Routing::Directives

    DEFAULT_MARSHALLERS = [JsonMarshaller.new]

    class << self
      def marshallers(*marshallers)
        @marshallers = marshallers unless marshallers.nil? || marshallers.empty?
        (@marshallers.nil? || @marshallers.empty?) ? DEFAULT_MARSHALLERS : @marshallers
      end

      def select_marshaller(media_ranges)
        weighted = marshallers.sort_by do |m|
          media_range = media_ranges.find { |mr| m.marshal_to?(mr) }
          media_range ? media_range.q : 0.0
        end
        weighted.last
      end
    end

    attr_reader :context

    class << self
      def routes
        @routes ||= []
      end

      def method_missing(name, *args, &block)
        if instance_methods.include?(name)
          routes << [name, args, block]
        else
          super
        end
      end
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @context = Context.new(Request.new(Rack::Request.new(env)), Response.new)

      accept = @context.request.header('Accept')
      marshaller = accept ? self.class.select_marshaller(accept.media_ranges) : self.class.marshallers.first

      catch (:complete) do
        begin
          if marshaller.nil?
            @context.rejections << Rejection.new(:accept, { supported: self.class.marshallers.map(&:media_type) })
          else
            self.class.routes.each do |route|
              name, args, block = route
              route_block = proc { instance_eval(&block) }
              send(name, *args, &route_block)
            end
          end
          handle_rejections(@context.rejections)
        rescue => e
          handle_error(e)
        end
      end

      marshaller ||= self.class.marshallers.first
      resp = @context.response.copy(
        headers: @context.response.headers.set(Headers::ContentType.new(marshaller.content_type)),
        body: marshaller.marshal(@context.response.body))
      [resp.status, resp.headers.map { |h| [h.name, h.to_s] }.to_h, resp.body]
    end

    def handle_error(e)
      puts "handle_error: #{e.class}: #{e}\n  #{e.backtrace.join("\n  ")}"
      case e
      when ParseError
        fail 400, e.message
      else
        fail 500, e.message # TODO: Only if verbose errors configured
      end
    end

    def handle_rejections(rejections)
      puts "handle_rejections: #{rejections}"
      if rejections.empty?
        fail 404
      else
        rejection = rejections.first
        case rejection.reason
        when :accept
          fail 406, "Supported media types: #{rejection[:supported].join(", ")}"
        when :header
          fail 400, "Missing required header: #{rejection[:required]}"
        when :method
          supported = rejections.take_while { |r| r.reason == :method }.map { |r| r[:supported].upcase }
          fail 405, "Supported methods: #{supported.join(", ")}"
        when :unauthorized
          if rejection[:scheme]
            challenge = Headers::Challenge.new(rejection[:scheme], rejection.info.except(:scheme))
            respond_with_header Headers::WWWAuthenticate.new(challenge) do
              fail 401
            end
          else
            fail 401
          end
        else
          fail 500
        end
      end
    end

  end

end
