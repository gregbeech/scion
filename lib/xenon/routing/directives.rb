Dir[File.join(__dir__, '*_directives.rb')].each { |f| require f }

module Xenon
  module Routing
    module Directives
      include RouteDirectives
      include HeaderDirectives
      include MethodDirectives
      include ParamDirectives
      include PathDirectives
    end
  end
end
