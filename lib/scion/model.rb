module Scion

  class MediaType
    attr_reader :type, :subtype, :params

    def initialize(type, subtype, params = {})
      @type = type
      @subtype = subtype
      @params = params
    end

    def self.parse(s)
      type, subtype, *param_list = s.split(/\s*[\/;]\s*/)
      params = Hash[param_list.map { |p| p.split(/\s*=\s*/) }]
      MediaType.new(type, subtype, params)
    end

    def with_q(q)
      MediaRange.new(self, q)
    end

    def =~(media_type)
      media_type = MediaType.parse(media_type) unless media_type.respond_to?(:type) && media_type.respond_to?(:subtype)
      [@type, '*'].include?(media_type.type) && [@subtype, '*'].include?(media_type.subtype) && media_type.params.all? { |n, v| @params[n] == v }
    end

    def to_s
      "#{@type}/#{@subtype}" << @params.map { |n, v| "; #{n}=#{v}" }.join
    end

    JSON = MediaType.new('application', 'json')
    XML = MediaType.new('application', 'xml')
  end

  class MediaRange
    include Comparable

    DEFAULT_Q = 1.0

    attr_reader :media_type, :q

    def initialize(media_type, q)
      @media_type = media_type
      @q = q.nil? ? DEFAULT_Q : q.to_f
    end

    def self.parse(s)
      media_type = MediaType.parse(s)
      q = media_type.params.delete('q')
      MediaRange.new(media_type, q)
    end

    [:type, :subtype, :params].each do |name|
      define_method(name) do
        @media_type.send(name)
      end
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

    def to_s
      s = "#{type}/#{subtype}"
      s << "; q=#{@q}" if q != DEFAULT_Q
      s << params.map { |n, v| "; #{n}=#{v}" }.join
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
