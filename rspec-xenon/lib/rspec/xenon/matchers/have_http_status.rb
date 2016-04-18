require 'rack/test'
require 'xenon/api'

module RSpec
  module Xenon
    module Matchers
      class HaveHttpStatus < RSpec::Matchers::BuiltIn::BaseMatcher
        include Rack::Test::Methods

        def initialize(route, status)
          @route = route
          @status = status
        end

        def supports_block_expectations?
          true
        end

        def matches?(request)
          @response = instance_eval(&request)
          @response.status == @status
        end

        def description
          "respond with status code #{@status}"
        end

        def failure_message
          "expected the response to have status code #{@status} but it was #{@response.status}"
        end

        def failure_message_when_negated
          "expected the response not to have status code #{@status} but it did"
        end

        private

        def app
          api_class = Class.new(::Xenon::API)
          api_class.class_eval(&@route)
          api_class.new
        end
      end

      def have_http_status(status)
        HaveHttpStatus.new(@route, status)
      end
    end
  end
end
