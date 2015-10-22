require 'xenon/routing/route_directives'

module Xenon
  module Routing
    module SecurityDirectives
      include RouteDirectives

      def authenticate(authenticator)
        extract_request(authenticator) do |user|
          if user
            yield user
          else
            reject :unauthorized, { scheme: authenticator.scheme }.merge(authenticator.auth_params)
          end
        end
      end

      def optional_authenticate(authenticator)
        extract_request(authenticator) do |user|
          yield user
        end
      end

      def authorize(check)
        if check.respond_to?(:call)
          extract_request(check) do |authorized|
            authorize(authorized) do
              yield
            end
          end
        elsif check
          yield
        else
          reject :forbidden
        end
      end

    end
  end
end