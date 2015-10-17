require 'rack/utils'

module Xenon
  module Routing
    module RouteDirectives

      def map_request(map)
        context.branch do
          context.request = map.respond_to?(:call) ? map.call(context.request) : context.request.copy(map)
          yield
        end
      end

      def map_response(map)
        context.branch do
          context.response = map.respond_to?(:call) ? map.call(context.response) : context.response.copy(map)
          yield
        end
      end

      def complete(status, body)
        map_response complete: true, status: Rack::Utils.status_code(status), body: body do
          throw :complete
        end
      end

      def reject(rejection, info = {})
        return if rejection.nil?
        rejection = Rejection.new(rejection, info) unless rejection.is_a?(Rejection)
        context.rejections << rejection
      end

      def fail(status, developer_message = nil)
        body = {
          status: status,
          developer_message: developer_message || Rack::Utils::HTTP_STATUS_CODES[status]
        }
        complete status, body
      end

      def extract(lambda)
        yield lambda.call(context)
      end

      def extract_request(lambda = nil)
        yield lambda ? lambda.call(context.request) : context.request
      end

    end
  end
end