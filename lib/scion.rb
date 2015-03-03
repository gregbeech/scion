require "json"
require "rack"
require "scion/routing"

module Scion

  module Rejections
    PATH = "PATH"
    METHOD = "METHOD"
  end

  class Result
    EMPTY = Result.new

    class Accept < Result
      attr_reader :status, :headers, :body

      def initialize(status, headers, body)
        @status = status
        @headers = headers
        @body = body
      end

      def complete?
        true
      end

      def to_s
        "Result::Complete(#{status})"
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

      def to_s
        "Result::Reject(#{reason}"
      end
    end

    def complete?
      false
    end

    def rejection?
      false
    end

    def to_s
      "Result::EMPTY"
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

  class Base
    include Rack::Utils
    include Scion::Routing

    attr_reader :request, :result

    def set_result(r)
      @result = r
    end

    def route
      raise NotImplementedError.new
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @request = Request.new(env)
      @result = Result::EMPTY

      begin
        catch (:complete) { route }
        @result = handle_rejections(@result) if @result.rejection?
      rescue => e
        @result = handle_errors(e)
      end

      [@result.status, @result.headers, [@result.body]]
    end

    def handle_errors(e)
      puts "ERROR: #{e}"
      @result = Result.error(500)
    end

    def handle_rejections(reject)
      case reject.reason
      when Rejections::PATH then Result.error(404)
      when Rejections::METHOD then Result.error(405)
      else Result.error(500)
      end
    end

  end

end
