module Scion
  module QuotedString
    refine String do
      def quote
        qs = self.gsub(/([\\"])/, '\\\\\1')
        self == qs ? self : %{"#{qs}"}
      end
    end
  end
end