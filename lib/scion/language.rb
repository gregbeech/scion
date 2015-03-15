module Scion

  class LanguageRange
    attr_reader :language, :q

    DEFAULT_Q = 1.0

    def initialize(language, q = DEFAULT_Q)
      @language = language
      @q = Float(q) || DEFAULT_Q
    end

    def <=>(other)
      @q <=> other.q
    end

    def to_s
      s = @language.dup
      s << "; q=#{@q}" if @q != DEFAULT_Q
      s
    end
  end

end