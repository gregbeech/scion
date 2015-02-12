# Scion

A Ruby HTTP framework inspired by [Spray][spray].

This is a just-for-fun proof of concept to see if it's possible to create a Spray-like routing DSL in Ruby, and to see whether it would feel "Rubyish".

A basic app looks something like this:

```ruby
class MyApp < Scion::Base
  route {
    path("/") {
      get {
        complete(200, "You got stuff")
      }.or post {
        complete(201, "You created stuff")
      }
    }
  }
end
```

To run it and start messing around just do:

```
$ bundle install
$ bundle exec shotgun
```


[spray]: http://spray.io/ "spray"