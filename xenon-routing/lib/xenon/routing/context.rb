module Xenon
  module Routing
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
  end
end