# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xenon/version'

Gem::Specification.new do |spec|
  spec.name          = 'xenon'
  spec.version       = Xenon::VERSION
  spec.authors       = ['Greg Beech']
  spec.email         = ['greg@gregbeech.com']
  spec.summary       = %q{An HTTP framework for building RESTful APIs.}
  spec.description   = %q{Provides a model for the HTTP protocol and a tree-based routing syntax.}
  spec.homepage      = 'https://github.com/gregbeech/xenon'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.2.0'

  spec.add_runtime_dependency 'activesupport', '~> 4.0'
  spec.add_runtime_dependency 'parslet', '~> 1.7'
  spec.add_runtime_dependency 'rack', '~> 1.6'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
