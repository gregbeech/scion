module Xenon
  class Protocol
    attr_reader :name, :version

    def initialize(name, version = nil)
      @name = name
      @version = version
    end

    def ==(other)
      other.is_a?(Protocol) && @name == other.name && @version == other.version
    end

    alias_method :eql?, :==

    def hash
      (@name.hash * 397) ^ @version.hash
    end
    
    def to_s
      @name && @version ? "#{@name}/#{@version}" : "#{@name}#{@version}"
    end

    HTTP_10 = new('HTTP', '1.0')
    HTTP_11 = new('HTTP', '1.1')
    HTTP_20 = new('HTTP', '2.0')
  end
end