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

      def request_marshaller(content_type)
        marshallers.find { |m| m.unmarshal?(content_type.media_type) }
      end

      def response_marshaller(media_ranges)
        weighted = marshallers.map do |marshaller|
          media_range = media_ranges.find { |media_range| marshaller.marshal?(media_range) }
          [marshaller, media_range ? media_range.q : 0]
        end
        weighted.select { |_, q| q > 0 }.sort_by { |_, q| q }.map { |m, _| m }.last
      end
    end

    attr_reader :context

    class << self
      alias_method :new!, :new unless method_defined? :new!

      def new
        instance = new!
        build(instance).to_app
      end

      # Creates a Rack::Builder instance with all the middleware set up and
      # the given +app+ as end point.
      def build(app)
        builder = Rack::Builder.new
        builder.use Rack::Head
        middleware.each { |mw, a, b| builder.use(mw, *a, &b) }
        builder.run app
        builder
      end

      def routes
        @routes ||= []
      end

      def middleware
        @middleware ||= []
      end

      def use(mw, *args, &block)
        middleware << [mw, args, block]
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
      response_marshaller = accept ? self.class.response_marshaller(accept.media_ranges) : self.class.marshallers.first

      catch :complete do
        begin
          if response_marshaller
            self.class.routes.each do |route|
              name, args, block = route
              route_block = proc { instance_eval(&block) }
              send(name, *args, &route_block)
            end
          else
            reject :accept, supported: self.class.marshallers.map(&:media_type)
          end
          handle_rejections { |r| default_rejection_handler(r) }
        rescue => error
          handle_error(error) { |e| default_error_handler(e) }
        end
      end

      response_marshaller ||= self.class.marshallers.first
      headers = @context.response.headers.set(Headers::ContentType.new(response_marshaller.content_type))
      body = response_marshaller.marshal(@context.response.body)
      resp = @context.response.copy(headers: headers, body: body)
      [resp.status, resp.headers.map { |h| [h.name, h.to_s] }.to_h, resp.body]
    end

    def handle_error(error, &handler)
      handler.call(error)
    end

    def handle_rejections(&handler)
      handler.call(@context.rejections)
    end

    def default_error_handler(error)
      puts "handle_error: #{error.class}: #{error}\n  #{error.backtrace.join("\n  ")}"
      case error
      when ParseError
        fail_with 400, error.message
      else
        fail_with 500, error.message # TODO: Only if verbose errors configured
      end
    end

    def default_rejection_handler(rejections)
      puts "handle_rejections: #{rejections}"
      if rejections.empty?
        fail_with 404
      else
        rejection = rejections.first
        case rejection.reason
        when :accept
          fail_with 406, "Supported media types: #{rejection[:supported].join(', ')}"
        when :forbidden
          fail_with 403
        when :header
          fail_with 400, "Missing required headers: #{Array(rejection[:required]).join(', ')}"
        when :method
          supported = rejections.take_while { |r| r.reason == :method }.flat_map { |r| r[:supported] }
          fail_with 405, "Supported methods: #{supported.map(&:upcase).join(', ')}"
        when :unauthorized
          if rejection[:scheme]
            challenge = Headers::Challenge.new(rejection[:scheme], rejection.info.except(:scheme))
            respond_with_header Headers::WWWAuthenticate.new(challenge) do
              fail_with 401
            end
          else
            fail_with 401
          end
        else
          fail_with 500
        end
      end
    end

  end
end