require "scion"

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