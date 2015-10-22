require 'xenon/routing/route_directives'

module Xenon
  module Routing
    module MarshallingDirectives
      include RouteDirectives

      def body(as: nil)
        extract_request do |request|
          if as == IO
            yield request.body
          elsif as == String
            yield request.body.read
          else
            content_type = request.header('Content-Type')
            marshaller = Xenon::API.request_marshaller(content_type.content_type) # yuk
            yield marshaller.unmarshal(request.body, as: as)
          end
        end
      end

    end
  end
end