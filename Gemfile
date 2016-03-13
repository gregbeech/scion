source 'https://rubygems.org'

gemspec

Dir[File.join('*', '*.gemspec')].each do |gemspec|
  lib = gemspec.scan(/xenon-(.*)\.gemspec/).flatten.first
  gemspec(name: "xenon-#{lib}", development_group: lib)
end

group :development, :test do
  gem 'rake', require: false
  gem 'rspec', require: false
  gem 'guard', require: false
  gem 'guard-rspec', require: false
  gem 'thin', require: false
  gem 'yard', require: false
  gem 'google-protobuf', '>= 3.0.0.alpha', require: false
end

group :development do
  gem 'shotgun', require: false
end

group :test do
  gem "codeclimate-test-reporter", require: false
end
