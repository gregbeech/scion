module Scion

  class ContentCodingRange
    attr_reader :coding, :q

    DEFAULT_Q = 1.0

    def initialize(coding, q = DEFAULT_Q)
      @coding = coding
      @q = Float(q) || DEFAULT_Q
    end

    def <=>(other)
      @q <=> other.q
    end

    def to_s
      s = @coding.dup
      s << "; q=#{@q}" if @q != DEFAULT_Q
      s
    end
  end

end