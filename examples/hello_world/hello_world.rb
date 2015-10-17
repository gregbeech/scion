require 'xenon'

class HelloWorld < Xenon::API
  authenticator = Xenon::BasicAuth.new realm: 'hello world' do |credentials|
    credentials.username # should actually auth here!
  end

  path '/' do
    get do
      authenticate(authenticator) do |user|
        params :greeting do |greeting|
          complete :ok, { greeting => user }
        end
      end
    end
  end
end
