require 'parslet'
require 'scion/errors'

module Scion

  module Parsers
    class MediaTypeParser < Parslet::Parser
      rule(:space?) { match('\s').repeat }

      %w(application audio image message model multipart text video).each do |t|
        rule(t.to_sym) { str(t) }
      end
      rule(:type) { (application | audio | image | message | model | multipart | text | video).as(:type) }
      rule(:slash) { str('/') }
      rule(:subtype) { match('[a-zA-Z0-9\.\-\+]').repeat(1).as(:subtype) >> space? }

      rule(:semicolon) { str(';') >> space? }
      rule(:name) { match('[^;=\s]').repeat(1).as(:name) >> space? }
      rule(:equals) { str('=') >> space? }
      rule(:value) { match('[^;\s]').repeat(1).as(:value) >> space? }
      rule(:param) { semicolon >> name >> (equals >> value).maybe >> space? }
      rule(:params) { param.repeat.as(:params) }

      rule(:media_type) { type >> slash >> subtype >> params }
      root(:media_type)
    end

    class MediaRangeParser < MediaTypeParser
      rule(:wildcard) { str('*') }
      rule(:wild_media_range) { wildcard.as(:type) >> slash >> wildcard.as(:subtype) >> params }
      rule(:root_media_range) { type >> slash >> (wildcard.as(:subtype) | subtype) >> params }
      
      rule(:media_range) { wild_media_range | root_media_range }
      root(:media_range)
    end

    class MediaTypeTransform < Parslet::Transform
      rule(name: simple(:n), value: simple(:v)) { [n.str, v.str] }
      rule(name: simple(:n)) { [n.str, nil] }
      rule(type: simple(:t), subtype: simple(:s), params: subtree(:p)) { { type: t.str, subtype: s.str, params: Hash[p] } }
    end
  end

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
