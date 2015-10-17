require 'json'
require 'rack'
require 'xenon/routing'

module Xenon
  class API
    include Xenon::Routing::Directives

    DEFAULT_MARSHALLERS = [JsonMarshaller.new]

    class << self
      def marshallers(*marshallers)
        @marshallers = marshallers unless marshallers.nil? || marshallers.empty?
        (@marshallers.nil? || @marshallers.empty?) ? DEFAULT_MARSHALLERS : @marshallers
      end

      def select_marshaller(media_ranges)
        weighted = marshallers.map do |marshaller|
          media_range = media_ranges.find { |media_range| marshaller.marshal_to?(media_range) }
          [marshaller, media_range ? media_range.q : 0]
        end
        weighted.select { |_, q| q > 0 }.sort_by { |_, q| q }.map { |m, _| m }.last
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
      @context = Routing::Context.new(Request.new(Rack::Request.new(env)), Response.new)

      accept = @context.request.header('Accept')
      marshaller = accept ? self.class.select_marshaller(accept.media_ranges) : self.class.marshallers.first

      catch (:complete) do
        begin
          if marshaller
            self.class.routes.each do |route|
              name, args, block = route
              route_block = proc { instance_eval(&block) }
              send(name, *args, &route_block)
            end
          else
            reject :accept, supported: self.class.marshallers.map(&:media_type)
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
        when :forbidden
          fail 403
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