module Scion
  module Routing

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

    def path(pattern)
      if pattern.is_a?(Regexp) && md = request.path.match(pattern)
        cancel_rejections(Rejection::PATH)
        yield *md.captures
      elsif pattern == request.path
        cancel_rejections(Rejection::PATH)
        yield
      else
        reject(Rejection.new(Rejection::PATH))
      end
    end

    ['DELETE', 'GET', 'HEAD', 'PATCH', 'POST', 'PUT'].each do |verb|
      define_method(verb.downcase) do |&inner|
        if request.request_method == verb
          cancel_rejections(Rejection::METHOD)
          inner.call
        else
          reject(Rejection.new(Rejection::METHOD, { supported: verb }))
        end 
      end
    end

    def form_hash
      yield request.POST
    end

  end
end
