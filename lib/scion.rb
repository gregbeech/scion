require "rack"

module Scion

  class Rejection; end

  class PathRejection < Rejection; end

  class MethodRejection < Rejection
    def initialize(supported)
      @supported = supported
    end
  end


  class RouteNode
    attr_reader :name, :children

    def initialize(name, children = [])
      @name = name
      @children = children
    end

    def each
      stack = [self]
      until stack.empty? do
        n = stack.pop
        yield n
        n.children.reverse.each { |c| stack.push(c) }
      end
    end

    def <<(child)
      @children.push(child)
      self
    end

    def call(req, res)
      raise NotImplementedError.new # to be implemented in derived class
    end

    def to_s
      "#{self.class}(#{@name}, children = #{@children.size})"
    end

    def or(other)
      OneOfNode.new(self, other)
    end
  end

  class BlockNode < RouteNode
    def initialize(name, children = [])
      super(name, children)
      @block = Proc.new
    end

    def call(req, res)
      @block.call(req, res)
    end
  end

  class OneOfNode < RouteNode
    def initialize(*children)
      super("oneOf", children)
    end

    def call(req, res)
      @children.each_with_object([]) do |c, obj|
        result = c.call(req, res)
        break result unless result.respond_to?(:any?) && result.any? { |v| v.is_a?(Rejection) }
        obj.push(result)
      end
    end

    def or(other)
      @children << other
    end
  end


  class Request < Rack::Request
  end

  class Response < Rack::Response
  end


  class Base

    class << self
      attr_reader :routes

      def route     
        (@routes ||= []) << yield
      end

      def path(path)
        node = BlockNode.new("path:#{path}") do |req, res|
          if req.path == path
            node.children.first.call(req, res)
          else
            [PathRejection.new]
          end
        end
        node << yield
      end

      def get
        node = BlockNode.new("get") do |req, res|
          if req.request_method == "GET"
            node.children.first.call(req, res)
          else
            [MethodRejection.new("GET")]
          end
        end
        node << yield
      end

      def post
        node = BlockNode.new("post") do |req, res|
          if req.request_method == "POST"
            node.children.first.call(req, res)
          else
            [MethodRejection.new("POST")]
          end
        end
        node << yield
      end

      def complete(*args)
        BlockNode.new("complete") do |req, res|
          headers = { 
            "Content-Length" => args[1].size.to_s,
            "Content-Type" => "text/plain"
          }
          [args[0], headers, [args[1]]]
        end
      end

    end

    # ------------------

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      # puts self.class.routes

      request = Request.new(env)
      response = Response.new

      self.class.routes.each do |route|
        ress = route.call(request, response)
        p ress
        return ress
        # route.each do |node|
        #   puts node
        #   p node.call(request, response)
        # end
      end

      content = "Hello World"

      headers = { 
        "Content-Length" => content.size.to_s,
        "Content-Type" => "text/plain"
      }

      [200, headers, [content]]
    end



  end


end