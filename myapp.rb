require "scion"

class MyApp < Scion::Base

  route {
    path("/") {
      get {
        complete(200, { wow: "You got stuff" })
      }.or post {
        complete(201, { cool: "You created stuff" })
      }
    }
  }

end