require 'xenon/quoted_string'

module Xenon
  class BasicCredentials
    attr_reader :username, :password

    def initialize(username, password)
      @username = username
      @password = password
    end

    def token
      Base64.strict_encode64("#{@username}:#{@password}")
    end

    def self.decode(s)
      str = Base64.strict_decode64(s)
      username, password = str.split(':', 2)
      BasicCredentials.new(username, password)
    end

    def to_s
      "Basic #{token}"
    end
  end

  class GenericCredentials
    using QuotedString

    attr_reader :scheme, :token, :params

    def initialize(scheme, token: nil, params: {})
      @scheme = scheme
      @token = token
      @params = params
    end

    def to_s
      s = @scheme.dup
      s << ' ' << @token if @token
      s << ' ' << @params.map { |n, v| "#{n}=#{v.quote}" }.join(', ')
      s
    end
  end

  class BasicAuth
    attr_reader :auth_params

    def initialize(auth_params = {}, &store)
      @auth_params = auth_params
      @store = store
    end

    def scheme
      'Basic'
    end

    def call(request)
      header = request.header('Authorization') rescue nil
      @store.call(header.credentials) if header && header.credentials.is_a?(BasicCredentials)
    end
  end
end