require 'xenon/errors'
require 'xenon/parsers/media_type'

module Xenon

  # A media type.
  #
  # @see ContentType
  # @see MediaRange
  class MediaType
    attr_reader :type, :subtype, :params

    # Initializes a new instance of MediaType.
    #
    # @param type [String] The main type, e.g. 'application'.
    # @param subtype [String] The subtype, e.g. 'json'.
    # @param params [Hash] Any params for the media type; don't use 'q' or 'charset'.
    def initialize(type, subtype, params = {})
      @type = type
      @subtype = subtype
      @params = params
    end

    # Parses a media type.
    #
    # @param s [String] The media type string.
    # @return [MediaType] The media type.
    def self.parse(s)
      tree = Parsers::MediaType.new.parse(s)
      Parsers::MediaTypeTransform.new.apply(tree)
    rescue Parslet::ParseFailed
      raise Xenon::ParseError.new("Invalid media type (#{s}).")
    end

    %w(application audio image message multipart text video).each do |type|
      define_method "#{type}?" do
        @type == type
      end
    end

    def experimental?
      @subtype.start_with?('x.') # not x- see http://tools.ietf.org/html/rfc6838#section-3.4
    end

    def personal?
      @subtype.start_with?('prs.')
    end

    def vendor?
      @subtype.start_with?('vnd.')
    end

    %w(ber der fastinfoset json wbxml xml zip).each do |format|
      define_method "#{format}?" do
        @subtype == format || @subtype.end_with?("+#{format}")
      end
    end

    def ==(other)
      @type == other.type && @subtype == other.subtype && @params == other.params
    end

    # Creates a {MediaRange} using this media type with a quality factor.
    #
    # @param q [Numeric] A value between 1.0 (most desirable) and 0.0 (not acceptable).
    # @return [MediaRange] The media range.
    def with_q(q)
      MediaRange.new(self, q)
    end

    # Creates a {ContentType} using this media type with a charset.
    #
    # @param charset [String] The desired charset, e.g. 'utf-8'.
    # @return [ContentType] The content type.
    def with_charset(charset)
      ContentType.new(self, charset)
    end

    def to_s
      "#{@type}/#{@subtype}" << @params.map { |n, v| v ? "; #{n}=#{v}" : "; #{n}" }.join
    end

    JSON = MediaType.new('application', 'json')
    XML = MediaType.new('application', 'xml')
  end

  # A content type.
  class ContentType
    attr_reader :media_type, :charset

    DEFAULT_CHARSET = 'utf-8' # historically iso-8859-1 but see http://tools.ietf.org/html/rfc7231#appendix-B

    def initialize(media_type, charset = DEFAULT_CHARSET)
      @media_type = media_type
      @charset = charset
    end

    def self.parse(s)
      media_type = MediaType.parse(s)
      charset = media_type.params.delete('charset') || DEFAULT_CHARSET
      ContentType.new(media_type, charset)
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
      @q = Float(params.delete('q')) rescue DEFAULT_Q
      @params = params
    end

    def self.parse(s)
      tree = Parsers::MediaRange.new.parse(s)
      Parsers::MediaTypeTransform.new.apply(tree)
    rescue Parslet::ParseFailed
      raise Xenon::ParseError.new("Invalid media range (#{s})")
    end

    def <=>(other)
      dt = compare_types(@type, other.type)
      return dt if dt != 0
      ds = compare_types(@subtype, other.subtype)
      return ds if ds != 0
      dp = params.size <=> other.params.size
      return dp if dp != 0
      @q <=> other.q
    end

    def =~(media_type)
      (type == '*' || type == media_type.type) &&
      (subtype == '*' || subtype == media_type.subtype) &&
      params.all? { |n, v| media_type.params[n] == v }
    end

    alias_method :===, :=~

    def to_s
      s = "#{@type}/#{@subtype}"
      s << @params.map { |n, v| v ? "; #{n}=#{v}" : "; #{n}" }.join
      s << "; q=#{@q}" if @q != DEFAULT_Q
      s
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
