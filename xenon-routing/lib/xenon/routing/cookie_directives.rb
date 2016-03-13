require 'xenon/routing/route_directives'

module Xenon
  module Routing
    module CookieDirectives
      include RouteDirectives

      def optional_cookie(name)
        optional_cookie(name, &proc)
      end

      def cookie(name)
        cookies(name, &proc)
      end

      def optional_cookies(*names)
        extract_request do |request|
          yield names.map { |name| request.cookie(name) }
        end
      end

      def cookies(*names)
        optional_cookies(*names) do |values|
          if values.all?
            yield *values
          else
            reject Rejection.new(:cookie, { required: names })
          end
        end
      end

    end
  end
end
