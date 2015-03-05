# Scion

A Ruby HTTP framework inspired by [Spray][spray].

This is a just-for-fun proof of concept to see if it's possible to create a Spray-like routing DSL in Ruby, and to see whether it would feel "Rubyish". It's pretty small (a few hundred lines of code) but does work, albeit synchronously rather than asynchronously like spray.
A basic app looks something like this, where the route is defined as a tree:

```ruby
require 'scion'

class MyApp < Scion::Base

  def route
    path '/' do
      get do        
        query_hash do |query|
          complete 200, { hello: 'World' }.merge(query)
        end
      end
      post do
        form_hash do |form|
          complete 201, { created: 'OK' }.merge(form)
        end
      end
    end
    path_prefix '/users' do
      path_end do
        get do
          complete 200, [{ user_id: 123 }, { user_id: 456 }]
        end
      end
      path '/([0-9]+)' do |user_id|
        get do
          complete 200, { user_id: user_id }
        end
      end
    end
  end

end
```

Thanks to the tree structure, it can respond with appropriate status codes, e.g. if you send `PATCH /` then it knows the path is valid but the method isn't so it returns `405 Method Not Allowed`.

I should probably write some tests soon, but the whole thing is so unstable at the moment that it doesn't seem worth it yet.

To run it and start messing around just do:

```
$ bundle install
$ bundle exec shotgun
```


[spray]: http://spray.io/ "spray"