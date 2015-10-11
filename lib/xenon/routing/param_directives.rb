require 'xenon/routing/route_directives'

module Xenon
  module Routing
    module ParamDirectives
      include RouteDirectives

      def form_hash
        extract_request do |request|
          yield request.form_hash
        end
      end

      def query_hash
        extract_request do |request|
          yield request.query_hash
        end
      end

    end
  end
end