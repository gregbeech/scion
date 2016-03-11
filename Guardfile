clearing :on

guard :rspec, cmd: 'bundle exec rspec', spec_paths: ['xenon-http/spec', 'xenon-routing/spec'] do
  %w(http routing).each do |lib|
    watch(%r{^xenon-#{lib}/spec/.+_spec\.rb$})
    watch(%r{^xenon-#{lib}/lib/(.+)\.rb$}) { |m| "xenon-#{lib}/spec/lib/#{m[1]}_spec.rb" }
    watch('xenon-#{lib}/spec/spec_helper.rb') { 'spec' }
  end
end
