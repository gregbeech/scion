module Scion
  module Routing

    module RouteDirectives
      def map_request(map)
        context.branch do
          context.request = map.respond_to?(:call) ? map.call(context.request) : context.request.copy(map)
          yield
        end
      end

      def map_response(map)
        context.branch do
          context.response = map.respond_to?(:call) ? map.call(context.response) : context.response.copy(map)
          yield
        end
      end

      def complete(status, body)
        map_response complete: true, status: status, body: body do
          throw :complete
        end
      end

      def reject(rejection)
        context.rejections << rejection unless rejection.nil?
      end

      def extract(lambda)
        yield lambda.call(context)
      end

      def extract_request(lambda = nil)
        yield lambda ? lambda.call(context.request) : context.request
      end
    end

    module HeaderDirectives
      def optional_header(name)
        extract_request do |request|
          yield request.header(name)
        end
      end

      def header(name)
        optional_header(name) do |value|
          if value
            yield value
          else
            reject Rejection.new(Rejection::HEADER, { required: name })
          end
        end
      end

      def respond_with_header(header)
        map_response -> r { r.copy(headers: r.headers.add(header)) } do
          yield
        end
      end
    end

    module MethodDirectives
      include RouteDirectives

      def request_method(method)
        extract_request do |request|
          if request.request_method == method
            yield
          else
            reject Rejection.new(Rejection::METHOD, { supported: method })
          end
        end
      end

      %i(delete get head options patch post put).each do |method|
        define_method(method) do |&inner|
          request_method(method, &inner)
        end
      end
    end

    module ParamDirectives
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

      def path_end(&inner)
        path_prefix(/\Z/, &inner)
      end

      def path(pattern, &inner)
        path_prefix(pattern) do |*captures|
          path_end do
            inner.call(*captures)
          end
        end
      end
    end

    module Directives
      include HeaderDirectives
      include MethodDirectives
      include ParamDirectives
      include PathDirectives
    end

  end
end
