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

    end
  end
end