module Xenon
  module QuotedString
    refine String do
      def quote
        qs = gsub(/([\\"])/, '\\\\\1')
        self == qs ? self : %{"#{qs}"}
      end

      def unquote
        qs = start_with?('"') && end_with?('"') ? self[1..-2] : self
        qs.gsub(/\\(.)/, '\1')
      end

      def uncomment
        qs = start_with?('(') && end_with?(')') ? self[1..-2] : self
        qs.gsub(/\\(.)/, '\1')
      end
    end
  end
end