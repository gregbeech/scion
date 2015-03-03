require "json"
require "rack"
require "scion/routing"

module Scion

  class Rejection
    PATH = "PATH"
    METHOD = "METHOD"

    attr_reader :reason, :info

    def initialize(reason, info = {})
      @reason = reason
      @info = info
    end

    def to_s
      "Rejection(#{reason})"
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

      def to_s
        "Result::Complete(#{status})"
      end
    end

    class Reject < Result
      attr_reader :rejections

      def initialize(*rejections)
        @rejections = rejections
      end

      def reject?
        true
      end

      def

      def to_s
        "Result::Reject(#{rejections.map { |r| r.reason }.join(", ")}"
      end
    end

    def complete?
      false
    end

    def reject?
      false
    end

    def to_s
      "Result::EMPTY"
    end

    def self.error(status, developer_message = nil)
      body = { 
        status: status, 
        developer_message: developer_message || Rack::Utils::HTTP_STATUS_CODES[status]
      }.to_json
      headers = { 
        "Content-Length" => body.size.to_s,
        "Content-Type" => "application/json"
      }
      Result::Complete.new(status, headers, body)
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
        @result = handle_rejections(@result.rejections) if @result.reject?
      rescue => e
        @result = handle_errors(e)
      end

      @result = Result.error(501, "The routing tree is incomplete") unless result.complete?
      [@result.status, @result.headers, [@result.body]]
    end

    def handle_errors(e)
      puts "handle_errors: #{e}"
      @result = Result.error(500)
    end

    def handle_rejections(rejections)
      puts "handle_rejections: #{rejections}"
      case rejections.first.reason
      when Rejection::PATH then Result.error(404)
      when Rejection::METHOD then Result.error(405)
      else Result.error(500)
      end
    end

  end

end
