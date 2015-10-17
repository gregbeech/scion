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

      def authorize(check)
        check = check.call if check.respond_to?(:call)
        if check
          yield
        else
          reject :forbidden
        end
      end

    end
  end
end