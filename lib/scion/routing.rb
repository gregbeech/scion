module Scion
  module Routing

    def path(pattern)
      puts "path: #{pattern}"
      if pattern.is_a?(Regexp) && md = request.path.match(pattern)
        yield *md.captures
      elsif pattern == request.path
        yield
      else
        reject(Rejections::PATH)
      end
    end

    def post
      puts "method: #{request.request_method}"
      if request.request_method == 'POST'
        yield
      else
        reject(Rejections::METHOD, supported: 'POST')
      end
    end

    def get
      puts "method: #{request.request_method}"
      if request.request_method == 'GET'
        yield
      else
        reject(Rejections::METHOD, supported: 'GET')
      end
    end

    def complete(status, body)
      puts "completing: #{status}"
      set_result Result::Accept.new(status, { "Content-Type" => "application/json" }, body.to_json)
      throw :complete
    end

    def reject(reason, info = {})
      puts "rejecting: #{reason} #{info}"
      set_result Result::Reject.new(reason, info) # should chain related rejections
    end

  end
end
