module Xenon
  class Error < StandardError; end
  class ParseError < Error; end
  class ProtocolError < Error; end
end
