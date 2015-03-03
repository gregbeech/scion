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
        @rejections = rejections
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
  end

  class Base
    include Scion::Routing::Directives

    attr_reader :request, :result

    def route
      raise NotImplementedError.new
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @request = Request.new(Rack::Request.new(env))
      @result = Result::EMPTY

      begin
        catch (:complete) { route }
        @result = handle_rejections(@result.rejections) if @result.reject?
      rescue => e
        @result = handle_error(e)
      end

      @result = Result.error(501, "The routing tree is incomplete") unless result.complete?
      [@result.status, @result.headers, [@result.body]]
    end

    def handle_error(e)
      puts "handle_error: #{e}"
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

    private

    def set_result(result)
      @result = result
    end

  end

end
