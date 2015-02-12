require "json"
require "rack"
require "scion/routing"

module Scion

  class Rejection; end

  class PathRejection < Rejection; end

  class MethodRejection < Rejection
    def initialize(supported)
      @supported = supported
    end
  end

  ###########################################################################

  class Request < Rack::Request
  end

  class Response < Rack::Response
  end

  ###########################################################################

  class Base
    include Rack::Utils
    extend Scion::Routing

    class << self
      attr_reader :routes

      def route     
        (@routes ||= []) << yield
      end
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      request = Request.new(env)
      response = Response.new

      result = []
      self.class.routes.each do |route|
        result = route.call(request, response)
        return result unless Routing.is_rejection?(result)
      end

      handle_rejections(result)
    end

    def handle_rejections(rejections)
      primary = rejections.first
      case primary
      when PathRejection then error(404)
      when MethodRejection then error(405)
      else error(500)
      end
    end

    private

    # TODO: This properly
    def error(status)
      payload = { 
        status: status, 
        developer_message: Rack::Utils::HTTP_STATUS_CODES[status]
      }.to_json
      headers = { 
        "Content-Length" => payload.size.to_s,
        "Content-Type" => "application/json"
      }
      [status, headers, [payload]]
    end

  end

end