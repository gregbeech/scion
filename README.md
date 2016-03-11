# Xenon

[![Gem Version][fury-badge]][fury] [![Build Status][travis-badge]][travis] [![Code Climate][cc-badge]][cc] [![Test Coverage][ccc-badge]][ccc] [![YARD Docs][docs-badge]][docs]

An HTTP framework for building RESTful APIs. As you can probably tell from the very low version number, this is in very early stages of development so I wouldn't use it anywhere close to production yet. But have a play around and let me know what you think, I'm very open to feedback.

The **xenon** gem is a top-level gem that simply pulls in the other gems for convenience.

## xenon-http

A set of model objects for the HTTP protocol which can parse and format the strings you typically get into proper objects you can work with. At the moment this covers key things like media types and the most common headers, but it will expand to cover the whole protocol. You can use the model by itself without any other parts of the library.

This is how things tend to look:

```ruby
accept = Xenon::Headers::Accept.parse('application/json, application/*; q=0.5')
accept.media_ranges.first.media_type.json? #=> true
accept.media_ranges.last.q #=> 0.5
# etc.
```

Yeah, it's not exciting and it's not glamorous, but if you need to parse parts of the HTTP protocol that other frameworks just don't reach, Xenon is here for you.

## xenon-routing

A tree-based routing approach using "directives" which gives you great flexibility in building APIs and without the need to write extensions, helpers, etc. because everything is a directive and you extend it by simply writing more directives!

A really simple example with a custom authentication directive is shown below, assuming an ActiveRecord-style `Salutation` model which supports `from_json` and `to_json`. You can run this from the [examples](examples/hello_world) directory!

~~~ruby
class HelloWorld < Xenon::API
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
~~~

Authentication and authorisation are split so if you don't pass an auth token, or pass a badly formed token that can't be read as Basic credentials, you'll be unauthorised:

~~~json
{
  "status": 401,
  "developer_message": "Unauthorized"
}
~~~

Whereas if you pass well a well-formed token with a username that isn't "greg" and you'll be forbidden:

~~~json
{
  "status": 403,
  "developer_message": "Forbidden"
}
~~~

And, of course, it does all the things you'd expect from a decent API library like content negotiation and returning the correct status codes when paths or methods aren't found. For example, if you try to `PUT` you'll see the error:

~~~json
{
  "status": 405,
  "developer_message": "Supported methods: GET, HEAD, POST"
}
~~~

Or if you send it an `Accept` header that doesn't allow JSON (the only supported format by default) you'll see:

~~~ruby
{
  "status": 406,
  "developer_message": "Supported media types: application/json"
}
~~~

## Spray

Xenon is inspired by [Spray][spray], an awesome Scala framework for building RESTful APIs, and which I sorely miss while working in Ruby. However although it's inspired by it, there are some key differences.

Firsly Xenon is synchronous rather than asynchronous, as that is a much more common approach to writing code in Ruby, and fits better with commonly used frameworks such as Rack and ActiveRecord. It's also much easier to write and reason about synchronous code, and you can still scale it pretty well using the process model.

Secondly the directives are just methods which are composed using Ruby's usual `yield` mechanism rather than being monads composed with flat map as in Spray. This is primarily to make the framework feel natural for Ruby users where the general desire is for simplicity and "it just works". This does limit composability of directives, but for most real-world situations this doesn't seem to be a problem so I think it's the right trade-off.

## Installation

Add this line to your application's Gemfile:

    gem 'xenon'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install xenon

## Contributing

1. Fork it ( https://github.com/gregbeech/xenon/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


[fury]: http://badge.fury.io/rb/xenon "Xenon at Rubygems"
[fury-badge]: https://badge.fury.io/rb/xenon.svg "Gem Version"
[travis]: https://travis-ci.org/gregbeech/xenon "Xenon at Travis CI"
[travis-badge]: https://travis-ci.org/gregbeech/xenon.svg "Build Status"
[cc]: https://codeclimate.com/github/gregbeech/xenon "Xenon Quality at Code Climate"
[cc-badge]: https://codeclimate.com/github/gregbeech/xenon/badges/gpa.svg "Code Quality"
[ccc]: https://codeclimate.com/github/gregbeech/xenon/coverage "Xenon Coverage at Code Climate"
[ccc-badge]: https://codeclimate.com/github/gregbeech/xenon/badges/coverage.svg "Code Coverage"
[docs]: http://www.rubydoc.info/github/gregbeech/xenon "YARD Docs"
[docs-badge]: http://img.shields.io/badge/yard-docs-blue.svg "YARD Docs"
[spray]: http://spray.io/ "spray"
