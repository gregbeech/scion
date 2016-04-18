# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec/xenon/version'

Gem::Specification.new do |spec|
  spec.name          = 'rspec-xenon'
  spec.version       = RSpec::Xenon::VERSION
  spec.authors       = ['Greg Beech']
  spec.email         = ['greg@gregbeech.com']
  spec.summary       = %q{Tree-based routing to build RESTful APIs on Rack.}
  spec.description   = %q{Provides tree-based routing syntax for building RESTful APIs.}
  spec.homepage      = 'https://github.com/gregbeech/xenon'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^rspec-xenon/bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^rspec-xenon/(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.2.0'

  spec.add_runtime_dependency 'rack-test', '>= 0.6.2'
end
