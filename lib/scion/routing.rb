module Scion
  module Routing

    # TODO: This feels messy
    def self.is_rejection?(result)
      result.respond_to?(:any?) && result.any? { |v| v.is_a?(Rejection) }
    end

    def path(path)
      Routing::Predicate.new("path:#{path}", yield) { |req, res| PathRejection.new if req.path != path }
    end

    def request_method(name)
      Routing::Predicate.new("method:#{name}", yield) { |req, res| MethodRejection.new(name) if req.request_method != name }
    end

    def delete(&route)
      request_method("DELETE", &route)
    end

    def get(&route)
      request_method("GET", &route)
    end

    def post(&route)
      request_method("POST", &route)
    end

    def put(&route)
      request_method("PUT", &route)
    end

    def complete(*args)
      # TODO: This properly
      Routing::Complete.new do |req, res|
        payload = args[1].to_json
        headers = { 
          "Content-Length" => payload.size.to_s,
          "Content-Type" => "application/json"
        }
        [args[0], headers, [payload]]
      end
    end

    ###########################################################################

    class Directive
      attr_reader :name, :children

      def initialize(name, *children)
        @name = name
        @children = children
      end

      def each
        stack = [self]
        until stack.empty? do
          n = stack.pop
          yield n
          n.children.reverse.each { |c| stack.push(c) } # TODO: better?
        end
      end

      def <<(child)
        @children.push(child)
        self
      end

      def call(req, res)
        raise NotImplementedError.new # to be implemented in derived class
      end

      def or(other)
        OneOf.new(self, other)
      end

      def to_s
        "#{self.class.name.split('::').last}(#{@name}, children = #{@children.size})"
      end

      def inspect(depth = 0)
        s = to_s << "\n"
        depth += 1
        @children.each { |c| s << ("  " * depth) << c.inspect(depth) }
        s
      end
    end

    class OneOf < Directive
      def initialize(*children)
        super("oneOf", *children)
      end

      def call(req, res)
        @children.each_with_object([]) do |c, obj|
          result = c.call(req, res)
          break result unless Routing.is_rejection?(result)
          obj.push(*result)
        end
      end

      def or(other)
        self << other
      end
    end

    class Predicate < Directive
      def initialize(name, *children)
        super(name, *children)
        @test = Proc.new
      end

      def call(req, res)
        rejection = @test.call(req, res)
        rejection ? [rejection] : children.first.call(req, res)
      end
    end

    class Complete < Directive
      def initialize
        super("complete")
        @block = Proc.new
      end

      def call(req, res)
        @block.call(req, res)
      end
    end

  end
end
