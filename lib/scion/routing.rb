module Scion
  module Routing

    module RouteDirectives
      def complete(status, body)
        context.result = Result::Complete.new(status, { 'Content-Type' => 'application/json' }, body.to_json)
        throw :complete
      end

      def reject(rejection)
        if context.result.reject?
          context.result.rejections << rejection unless rejection.nil?
        else
          context.result = Result::Reject.new(rejection)
        end
      end

      def extract(lambda)
        yield lambda.call(context)
      end

      def extract_request(lambda = nil)
        yield lambda ? lambda.call(context.request) : context.request
      end

      def modify_request(lambda)
        context.branch do
          lambda.call(context.request)
          yield
        end
      end
    end

    module HeaderDirectives
      def header(name)
        optional_header(name) do |value|
          if value
            yield value
          else
            reject(Rejection.new(Rejection::HEADER, { required: name }))
          end
        end
      end

      def optional_header(name)
        extract_request do |request|
          yield request.header(name)
        end
      end

      def provides(*media_types)
        media_types = parse_media_types(media_types)
        optional_header 'Accept' do |accept|
          if accept
            media_type = accept.media_ranges.lazy.map { |mr| media_types.find { |mt| mt =~ mr } }.find { |x| x }
            if media_type
              yield media_type
            else
              reject(Rejection.new(Rejection::ACCEPT, { supported: media_types }))
            end
          else
            yield media_types.first
          end
        end
      end

      private

      def parse_media_types(media_types)
        media_types.map do |mt| 
          case mt
          when MediaType then mt
          when Symbol then MediaType.parse("application/#{mt}")
          else MediaType.parse(mt)
          end
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
            reject(Rejection.new(Rejection::METHOD, { supported: method }))
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
            modify_request(-> r { r.unmatched_path = match.post_match }) do
              yield *match.captures
            end
          else
            reject(nil) # path rejections are nil to allow more specific rejections to be seen
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
