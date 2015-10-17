require 'xenon/routing/route_directives'

module Xenon
  module Routing
    module ParamDirectives
      include RouteDirectives

      def param_hash
        extract_request do |request|
          yield request.param_hash
        end
      end

      def params(*names)
        param_hash do |hash|
          yield *hash.slice(*names).values
        end
      end

    end
  end
end