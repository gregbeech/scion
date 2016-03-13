require 'xenon/api'
require 'ostruct'

class Salutation
  attr_accessor :greeting, :username

  def initialize(attributes = {})
    @greeting = attributes[:greeting]
    @username = attributes[:username]
  end

  def from_json(json)
    data = JSON.load(json)
    @greeting = data['greeting']
    @username = data['username']
    self
  end

  def to_json
    JSON.dump(greeting: @greeting, username: @username)
  end
end

class HelloWorld < Xenon::API
  use Rack::MethodOverride

  path '/' do
    hello_auth do |user|
      get do
        params :greeting do |greeting|
          complete :ok, Salutation.new(greeting: greeting, username: user.username)
        end
      end
      post do
        body as: Salutation do |salutation|
          salutation.username = user.username
          complete :ok, salutation
        end
      end
    end
  end

  private

  def hello_auth
    authenticate authenticator do |user|
      authorize user.username == 'greg' do
        yield user
      end
    end
  end

  def authenticator
    @authenticator ||= Xenon::BasicAuth.new realm: 'hello world' do |credentials|
      OpenStruct.new(username: credentials.username) # should actually auth here!
    end
  end
end
