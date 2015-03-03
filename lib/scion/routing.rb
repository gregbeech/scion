module Scion
  module Routing

    module RouteDirectives
      def complete(status, body)
        set_result Result::Complete.new(status, { "Content-Type" => "application/json" }, body.to_json)
        throw :complete
      end

      def reject(rejection)
        if result.reject?
          result.rejections << rejection
        else
          set_result Result::Reject.new(rejection)
        end
      end

      def cancel_rejections(reason)
        if result.reject?
          result.rejections.delete_if { |r| r.reason == reason }
        end
      end
    end

    module FormDirectives
      def form_hash
        yield request.form_hash
      end
    end

    module MethodDirectives
      include RouteDirectives

      def request_method(method)
        if request.request_method == method
          cancel_rejections(Rejection::METHOD)
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

    module PathDirectives
      include RouteDirectives

      def path_prefix(pattern)
        path = request.unmatched_path
        match = path.match(pattern)
        if match && match.pre_match == ''
          cancel_rejections(Rejection::PATH)
          request.unmatched_path = match.post_match
          yield *match.captures
        else
          reject(Rejection.new(Rejection::PATH))
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
      include FormDirectives
      include MethodDirectives
      include PathDirectives
    end

  end
end
