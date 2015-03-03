module Scion
  module Routing

    def complete(status, body)
      puts "completing: #{status}"
      set_result Result::Accept.new(status, { "Content-Type" => "application/json" }, body.to_json)
      throw :complete
    end

    def reject(reason, info = {})
      puts "rejecting: #{reason} #{info}"
      set_result Result::Reject.new(reason, info) # should chain related rejections
    end

    def path(pattern)
      if pattern.is_a?(Regexp) && md = request.path.match(pattern)
        yield *md.captures
      elsif pattern == request.path
        yield
      else
        reject(Rejections::PATH)
      end
    end

    ['DELETE', 'GET', 'HEAD', 'PATCH', 'POST', 'PUT'].each do |verb|
      define_method(verb.downcase) do |&inner|
        if request.request_method == verb
          inner.call
        else
          reject(Rejections::METHOD, supported: verb)
        end 
      end
    end

    def form_hash
      yield request.form_data? ? request.POST : {}
    end

  end
end
