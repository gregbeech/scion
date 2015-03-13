module Scion

  class CharsetRange
    attr_reader :charset, :q

    DEFAULT_Q = 1.0

    def initialize(charset, q = DEFAULT_Q)
      @charset = charset
      @q = Float(q) || DEFAULT_Q
    end

    def <=>(other)
      @q <=> other.q
    end

    def to_s
      s = @charset.dup
      s << "; q=#{@q}" if @q != DEFAULT_Q
      s
    end
  end

end