require 'xenon/api'
require 'ostruct'

class HelloWorld < Xenon::API
  path '/' do
    hello_auth do |user|
      get do
        params :greeting do |greeting|
          complete :ok, { greeting => user.username }
        end
      end
      post do
        body do |body|
          complete :ok, { body['greeting'] => user.username }
        end
      end
    end
  end

  private

  def hello_auth
    @authenticator ||= Xenon::BasicAuth.new realm: 'hello world' do |credentials|
      OpenStruct.new(username: credentials.username) # should actually auth here!
    end
    authenticate @authenticator do |user|
      authorize user.username == 'greg' do
        yield user
      end
    end
  end
end
