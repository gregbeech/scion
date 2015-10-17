require 'xenon/routing/route_directives'

module Xenon
  module Routing
    module PathDirectives
      include RouteDirectives

      def path_prefix(pattern)
        extract_request do |request|
          match = request.unmatched_path.match(pattern)
          if match && match.pre_match == ''
            map_request unmatched_path: match.post_match do
              yield *match.captures
            end
          else
            reject nil # path rejections are nil to allow more specific rejections to be seen
          end
        end
      end

      def path_end
        path_prefix(/\Z/) do
          yield
        end
      end

      def path(pattern)
        path_prefix(pattern) do |*captures|
          path_end do
            yield *captures
          end
        end
      end

    end
  end
end