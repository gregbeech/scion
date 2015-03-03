require "scion"

class MyApp < Scion::Base

  route do
    path "/" do
      get do
        complete 200, { wow: "You got stuff" }
      end
      post do
        complete 201, { cool: "You created stuff" }
      end
    end
    path %r{^/([a-z]+)$} do |s|
      complete 200, { s => "bar" }
    end
  end

end