require 'xenon'

class HelloWorld < Xenon::API
  path '/' do
    query_hash do |query|
      complete 200, { hello: query['name'] || 'world' }
    end
  end
end
