module RSpec
  module Xenon
    module DirectiveExampleGroup

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        attr_accessor :route

        def route(&block)
          before { @route = block }
          after { @route = nil }
        end
      end

    end
  end
end
