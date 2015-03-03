require "json"
require "rack"
require "scion/routing"

module Scion

  module Rejections
    PATH = "PATH"
    METHOD = "METHOD"
  end

  class Result

    class Accept < Result
      attr_reader :status, :headers, :body

      def initialize(status, headers, body)
        @status = status
        @headers = headers
        @body = body
      end

      def rejection?
        false
      end

      def to_rack
        [@status, @headers, [@body]]
      end
    end

    class Reject < Result
      attr_reader :reason, :info

      def initialize(reason, info = {})
        @reason = reason
        @info = info
      end

      def rejection?
        true
      end
    end

    def self.error(status)
      body = { 
        status: status, 
        developer_message: Rack::Utils::HTTP_STATUS_CODES[status]
      }.to_json
      headers = { 
        "Content-Length" => body.size.to_s,
        "Content-Type" => "application/json"
      }
      Result::Accept.new(status, headers, body)
    end

  end

  class Request < Rack::Request
  end

  class Response < Rack::Response
  end

  ###########################################################################

  class Runner
    def initialize(delegate)
      @delegate = delegate
    end

    def run(&block)
      instance_eval &block
    end

    def method_missing(method, *args, &block)
      @delegate.send(method, *args, &block)
    end
  end

  class Base
    include Rack::Utils
    include Scion::Routing

    attr_reader :request

    def set_result(r)
      @result = r
    end

    class << self
      def route(&block)   
        @@route = block
      end
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @request = Request.new(env)
      @response = Response.new

      catch (:complete) { Runner.new(self).run(&@@route) }
      @result = handle_rejections if @result.rejection?
      @result.to_rack
    end

    def handle_rejections
      case @result.reason
      when Rejections::PATH then Result.error(404)
      when Rejections::METHOD then Result.error(405)
      else Result.error(500)
      end
    end

  end

end