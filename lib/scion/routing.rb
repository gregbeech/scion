module Scion
  module Routing

    module RouteDirectives
      def complete(status, body)
        set_result Result::Complete.new(status, { 'Content-Type' => 'application/json' }, body.to_json)
        throw :complete
      end

      def reject(rejection)
        if result.reject?
          result.rejections << rejection unless rejection.nil?
        else
          set_result Result::Reject.new(rejection)
        end
      end
    end

    module HeaderDirectives
      def header(name, &inner)
        optional_header(name) do |value|
          if value
            inner.call(value)
          else
            reject(Rejection.new(Rejection::HEADER, { required: name }))
          end
        end
      end

      def optional_header(name)
        yield request.header(name)
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
        if request.request_method == method
          yield
        else
          reject(Rejection.new(Rejection::METHOD, { supported: method }))
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
        yield request.form_hash
      end

      def query_hash
        yield request.query_hash
      end
    end

    module PathDirectives
      include RouteDirectives

      def path_prefix(pattern)
        path = request.unmatched_path
        match = path.match(pattern)
        if match && match.pre_match == ''
          request.unmatched_path = match.post_match
          yield *match.captures
        else
          reject(nil) # path rejections are nil to allow more specific rejections to be seen
        end
      ensure
        request.unmatched_path = path
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
