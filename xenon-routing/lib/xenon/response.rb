require 'xenon/headers'

module Xenon
  class Response
    attr_reader :status, :headers, :body

    def initialize
      @headers = Headers.new
      @complete = false
      freeze
    end

    def complete?
      @complete
    end

    def copy(changes = {})
      r = dup
      changes.each { |k, v| r.instance_variable_set("@#{k}", v) }
      r.freeze
    end

    def freeze
      @headers.freeze
      @body.freeze
      super
    end
  end
end
