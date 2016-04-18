require 'rspec/xenon/directive_example_group'
require 'rspec/xenon/matchers'

module RSpec
  module Xenon
    def self.initialize_configuration(config)
      config.include DirectiveExampleGroup, type: :xenon
      config.include Matchers
    end

    initialize_configuration RSpec.configuration
  end
end
