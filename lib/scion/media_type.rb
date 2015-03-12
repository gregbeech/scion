require 'scion/errors'
require 'scion/parsers'

module Scion

  class MediaType
    attr_reader :type, :subtype, :params

    def initialize(type, subtype, params = {})
      @type = type
      @subtype = subtype
      @params = params
    end

    def self.parse(s)
      tree = Parsers::MediaTypeParser.new.parse(s)
      tree = Parsers::MediaTypeTransform.new.apply(tree)
      MediaType.new(tree[:type], tree[:subtype], tree[:params])
    rescue Parslet::ParseFailed
      raise Scion::ParseError.new("Invalid media range (#{s})")
    end

    def with_q(q)
      MediaRange.new(self, q)
    end

    def with_charset(charset)
      ContentType.new(self, charset)
    end

    def to_s
      "#{@type}/#{@subtype}" << @params.map { |n, v| v ? "; #{n}=#{v}" : "; #{n}" }.join
    end

    JSON = MediaType.new('application', 'json')
    XML = MediaType.new('application', 'xml')
  end

  class ContentType
    attr_reader :media_type, :charset

    DEFAULT_ENCODING = Encoding::UTF_8

    def initialize(media_type, charset = DEFAULT_ENCODING)
      @media_type = media_type
      @charset = charset.is_a?(Encoding) ? charset : Encoding.find(charset)
    end

    def to_s
      "#{@media_type}; charset=#{@charset}"
    end
  end

  class MediaRange
    include Comparable

    DEFAULT_Q = 1.0

    attr_reader :type, :subtype, :q, :params

    def initialize(type, subtype, params = {})
      @type = type
      @subtype = subtype
      @q = (params.delete('q') || DEFAULT_Q).to_f
      @params = params
    end

    def self.parse(s)
      tree = Parsers::MediaRangeParser.new.parse(s)
      tree = Parsers::MediaTypeTransform.new.apply(tree)
      MediaRange.new(tree[:type], tree[:subtype], tree[:params])
    rescue Parslet::ParseFailed
      raise Scion::ParseError.new("Invalid media range (#{s})")
    end

    def <=>(other)
      dq = @q <=> other.q
      return dq if dq != 0
      dt = compare_types(@type, other.type)
      return dt if dt != 0
      ds = compare_types(@subtype, other.subtype)
      return ds if ds != 0
      params.size <=> other.params.size
    end 

    def =~(media_type)
      (type == '*' || type == media_type.type) &&
      (subtype == '*' || subtype == media_type.subtype) &&
      params.all? { |n, v| media_type.params[n] == v }
    end

    alias_method :===, :=~

    def to_s
      s = "#{@type}/#{@subtype}"
      s << "; q=#{@q}" if @q != DEFAULT_Q
      s << @params.map { |n, v| v ? "; #{n}=#{v}" : "; #{n}" }.join
    end

    private

    def compare_types(a, b)
      if a == b then 0
      elsif a == '*' then -1
      elsif b == '*' then 1
      else 0
      end
    end
  end

end
