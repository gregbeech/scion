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

  class Result
    EMPTY = Result.new

    class Complete < Result
      attr_reader :status, :headers, :body

      def initialize(status, headers, body)
        @status = status
        @headers = headers
        @body = body
      end

      def complete?
        true
      end
    end

    class Reject < Result
      attr_reader :rejections

      def initialize(*rejections)
        @rejections = rejections.compact
      end

      def reject?
        true
      end
    end

    def complete?
      false
    end

    def reject?
      false
    end

    def handled?
      complete? || reject?
    end

    def self.error(status, developer_message = nil)
      body = { 
        status: status, 
        developer_message: developer_message || Rack::Utils::HTTP_STATUS_CODES[status]
      }.to_json
      headers = { 
        'Content-Length' => body.size.to_s,
        'Content-Type' => 'application/json'
      }
      Result::Complete.new(status, headers, body)
    end

  end

  class Request
    attr_accessor :unmatched_path

    def initialize(rack_req)
      @rack_req = rack_req
      @unmatched_path = rack_req.path
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
      raw = @rack_req.env['HTTP_' + snake_name.upcase]

      class_name = snake_name.classify.to_sym
      begin
        klass = Scion::Headers.const_get(class_name)
        klass.parse(raw)
      rescue NameError
        raw
      end
    end
  end

  class Context
    attr_accessor :request, :response, :result

    def initialize(request)
      @request = request
      @result = Result::EMPTY
    end

    def branch
      original_request = @request.dup
      yield
    ensure
      @request = original_request
    end
  end

  class Base
    include Scion::Routing::Directives

    attr_reader :context

    def route
      raise NotImplementedError.new
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @context = Context.new(Request.new(Rack::Request.new(env)), Response.new)

      begin
        catch (:complete) { route }
        @context.result = handle_rejections(@context.result.rejections) if @context.result.reject?
      rescue => e
        @context.result = handle_error(e)
      end

      @context.result = Result.error(501, 'The routing tree is incomplete') unless @context.result.complete?
      [@context.result.status, @context.result.headers, [@context.result.body]]
    end

    def handle_error(e)
      puts "handle_error: #{e}"
      @context.result = Result.error(500)
    end

    def handle_rejections(rejections)
      puts "handle_rejections: #{rejections}"
      if rejections.empty?
        Result.error(404)
      else
        rejection = rejections.first
        case rejection.reason
        when Rejection::ACCEPT
          Result.error(406, "Supported media types: #{rejection[:supported].join(", ")}")
        when Rejection::HEADER
          Result.error(400, "Missing required header: #{rejection[:required]}")
        when Rejection::METHOD
          supported = rejections.take_while { |r| r.reason == Rejection::METHOD }.map { |r| r[:supported].upcase }
          Result.error(405, "Supported methods: #{supported.join(", ")}")
        else 
          Result.error(500)
        end
      end
    end

  end

end
