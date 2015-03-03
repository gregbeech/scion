# Scion

A Ruby HTTP framework inspired by [Spray][spray].

This is a just-for-fun proof of concept to see if it's possible to create a Spray-like routing DSL in Ruby, and to see whether it would feel "Rubyish".

A basic app looks something like this:

```ruby
class MyApp < Scion::Base

  def route
    path "/" do
      get do
        complete 200, { hello: "World" }
      end
      post do
        form_hash do |form|
          complete 201, { created: "OK" }.merge(form)
        end
      end
    end
    path %r{^/users/([0-9]+)$} do |user_id|
      get do
        complete 200, { user_id: user_id }
      end
    end
  end

end
```

To run it and start messing around just do:

```
$ bundle install
$ bundle exec shotgun
```


[spray]: http://spray.io/ "spray"