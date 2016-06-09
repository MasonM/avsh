require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require_relative 'lib/avsh/version'

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :script do
  avsh_libs = Dir['lib/avsh/*.rb'].map { |file| File.read(file) }.join("\n")
  template = File.read('avsh_singlefile_template.tpl')
  script = template % { avsh_version: Avsh::VERSION, avsh_libs: avsh_libs }

  File.open('avsh', 'w') do |file|
    file.write(script)
    file.chmod(0755)
  end
end
