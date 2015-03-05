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

      class_name = snake_name.classify.to_sym
      begin
        klass = Scion::Headers.const_get(class_name)
        klass.parse(value)
      rescue NameError
        Scion::Headers::Raw(name, value)
      end
    end
  end

  class Response
    attr_reader :status, :headers, :body

    def initialize
      @headers = {}
      @complete = false
    end

    def complete?
      @complete
    end

    def complete!(status, body)
      @status = status
      @body = body
      @complete = true
      self
    end

    def self.error(status, developer_message = nil)
      body = { 
        status: status, 
        developer_message: developer_message || Rack::Utils::HTTP_STATUS_CODES[status]
      }.to_json
      response = Response.new.complete!(status, body)
    end
  end

  class Context
    attr_accessor :request, :response, :rejections

    def initialize(request)
      @request = request
      @response = Response.new
      @rejections = []
    end

    def branch
      original_request = @request.dup
      original_response = @response.dup
      yield
    ensure
      @request = original_request
      @response = original_response unless @response.complete?
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
      @context = Context.new(Request.new(Rack::Request.new(env)))

      begin
        catch (:complete) { route }
        puts "complete? #{@context.response.complete?}"
        @context.response = handle_rejections(@context.rejections) unless @context.response.complete?
      # rescue => e
      #   @context.response = handle_error(e)
      end

      @context.response = Response.error(501, 'The routing tree is incomplete') unless @context.response.complete?
      [@context.response.status, @context.response.headers, [@context.response.body]]
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
