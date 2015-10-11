require 'xenon/routing/route_directives'

module Xenon
  module Routing
    module MethodDirectives
      include RouteDirectives

      def request_method(method)
        extract_request do |request|
          if request.request_method == method
            yield
          else
            reject Rejection.new(:method, { supported: method })
          end
        end
      end

      %i(delete get head options patch post put).each do |method|
        define_method(method) do |&inner|
          request_method(method, &inner)
        end
      end

    end
  end
end