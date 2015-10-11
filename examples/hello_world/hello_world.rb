require 'xenon'

class HelloWorld < Xenon::API
  path '/' do
    get do
      query_hash do |query|
        complete :ok, { hello: query['name'] || 'world' }
      end
    end
  end
end
