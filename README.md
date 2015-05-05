# Xenon 

[![Gem Version][fury-badge]][fury] [![Build Status][travis-badge]][travis] [![Code Climate][cc-badge]][cc] [![Test Coverage][ccc-badge]][ccc]

An HTTP framework for building RESTful APIs, inspired by [Spray][spray].

At the moment I probably wouldn't use this gem for anything you actually depend on because it's _very_ early in its lifecycle. However, this is a flavour of what's in here.

## HTTP Model

A set of model objects for the HTTP protocol which can parse and format the strings you typically get into proper objects you can work with. At the moment this covers key things like media types and the most common headers, but it will expand to cover the whole protocol. You can use the model by itself without any other parts of the library.

This is how things tend to look:

```ruby
accept = Xenon::Headers::Accept.parse('application/json, application/*; q=0.5')
accept.media_ranges.first.media_type.json? #=> true
accept.media_ranges.last.q #=> 0.5
# etc.
```

## Routing

A tree-based routing approach based on Spray, giving you great flexibility in building APIs and without the need to write extensions, helpers, etc. because everything is a directive and you extend it by simply writing directives! This is highly unstable and in flux at the moment.

This is the kind of syntax I'm aiming for which _sort of_ works, but needs a load of changes to allow composition so what's there now is really just a proof of concept of the basic syntax rather than anything close to useful.

```ruby
path_prefix 'users' do
  path_end do
    get do
      complete 200, User.all
    end
    post do
      body as: User do |user|
        user.save!
        respond_with_header 'Location' => "/users/#{user.id}" do
          complete 201, user
        end
      end
    end
  end
  path /[0-9]+/ do |user_id|
    get do
      complete 200, User.get_by_id(user_id)
    end
  end
end
```

Of course, it'll do all the things you'd expect like support content negotiation properly and return the correct status codes when paths or methods aren't found.

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
[spray]: http://spray.io/ "spray"
