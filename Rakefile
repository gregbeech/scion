# require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new

task :default => :spec
task :test => :spec

desc 'Build gems into the pkg directory'
task :build do
  FileUtils.rm_rf('pkg')
  Dir[File.join('*', '*.gemspec')].each do |gemspec|
    system "gem build #{gemspec}"
  end
    system "gem build xenon.gemspec"
  FileUtils.mkdir_p('pkg')
  FileUtils.mv(Dir['*.gem'], 'pkg')
end

desc 'Tags version, pushes to remote, and pushes gems'
task :release => :build do
  sh 'git', 'tag', '-m', changelog, "v#{Xenon::VERSION}"
  sh "git push origin master"
  sh "git push origin v#{Xenon::VERSION}"
  sh "ls pkg/*.gem | xargs -n 1 gem push"
end
