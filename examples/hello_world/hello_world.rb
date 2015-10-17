require 'xenon'
require 'ostruct'

class HelloWorld < Xenon::API
  path '/' do
    get do
      hello_auth do |user|
        params :greeting do |greeting|
          complete :ok, { greeting => user.username }
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
