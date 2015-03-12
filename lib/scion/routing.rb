module Scion
  module Routing

    class Route
      def call(context)
        raise NotImplementedError.new
      end

      class Complete < Route
        def initialize(status, body)
          @status = status
          @body = body
        end

        def call(context)
          context.complete!(@status, @body)
        end
      end

      class Reject < Route
        def initialize(*rejections)
          @rejections = rejections
        end

        def call(context)
          context.reject!(@rejections)
        end
      end
    end

    module RouteDirectives
      def complete(status, body)
        Route::Complete.new(status, body)
      end

      def reject(*rejections)
        Route::Reject.new(*rejections)
      end
    end

    class Directive
      def call(context)
        raise NotImplementedError.new
      end

      # def |(other)
      #   self # TODO
      # end

      class Extract < Directive
        def initialize(lambda, &block)
          @lambda = lambda
          @block = block
        end

        def call(context)
          extracted = @lambda.call(context)
          directive = @block.call(extracted)
          directive.call(context)
        end
      end
    end

    module BasicDirectives
      # def map_request(map)
      #   Directive.new do
      #     context.branch do
      #       context.request = map.respond_to?(:call) ? map.call(context.request) : context.request.copy(map)
      #       yield
      #     end
      #   end
      # end

      # def map_response(map)
      #   Directive.new do
      #     context.branch do
      #       context.response = map.respond_to?(:call) ? map.call(context.response) : context.response.copy(map)
      #       yield
      #     end
      #   end
      # end

      def extract(lambda, &inner)
        Directive::Extract.new(lambda, &inner)
      end

      # def extract_request(lambda = nil)
      #   Directive.new do
      #     yield lambda ? lambda.call(context.request) : context.request
      #   end
      # end

    end

    module HeaderDirectives
      # def optional_header(name)
      #   Directive.new do
      #     extract_request do |request|
      #       yield request.header(name)
      #     end
      #   end
      # end

      # def header(name)
      #   Directive.new do
      #     optional_header(name) do |value|
      #       if value
      #         yield value
      #       else
      #         reject Rejection.new(Rejection::HEADER, { required: name })
      #       end
      #     end
      #   end
      # end

      # def respond_with_header(header)
      #   Directive.new do
      #     map_response -> r { r.copy(headers: r.headers.add(header)) } do
      #       yield
      #     end
      #   end
      # end
    end

    module MethodDirectives
      include RouteDirectives

      def request_method(method)
        extract -> ctx { ctx.request.request_method } do |request_method|
          if request_method == method
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
      # def form_hash
      #   Directive.new do
      #     extract_request do |request|
      #       yield request.form_hash
      #     end
      #   end
      # end

      # def query_hash
      #   Directive.new do
      #     extract_request do |request|
      #       yield request.query_hash
      #     end
      #   end
      # end
    end

    module PathDirectives
      include RouteDirectives

      # def path_prefix(pattern)
      #   Directive.new do
      #     extract_request do |request|
      #       match = request.unmatched_path.match(pattern)
      #       if match && match.pre_match == ''
      #         map_request unmatched_path: match.post_match do
      #           yield *match.captures
      #         end
      #       else
      #         reject nil # path rejections are nil to allow more specific rejections to be seen
      #       end
      #     end
      #   end
      # end

      # def path_end(&inner)
      #   Directive.new do
      #     path_prefix(/\Z/, &inner)
      #   end
      # end

      # def path(pattern, &inner)
      #   Directive.new do
      #     path_prefix(pattern) do |*captures|
      #       path_end do
      #         inner.call(*captures)
      #       end
      #     end
      #   end
      # end
    end

    module Directives
      include RouteDirectives
      include BasicDirectives
      include HeaderDirectives
      include MethodDirectives
      include ParamDirectives
      include PathDirectives
    end

  end
end
