require 'xenon/routing/route_directives'

module Xenon
  module Routing
    module MethodDirectives
      include RouteDirectives

      def request_method(*methods)
        extract_request do |request|
          if methods.include?(request.request_method)
            yield
          else
            reject Rejection.new(:method, { supported: method })
          end
        end
      end

      def get
        request_method :get, :head do
          yield
        end
      end

      %i(delete head options patch post put).each do |method|
        define_method(method) do |&inner|
          request_method(method, &inner)
        end
      end

    end
  end
end