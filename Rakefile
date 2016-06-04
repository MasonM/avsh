require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :script do
  script_files = [
    'script_parts/shebang.sh',
    'lib/avsh/*.rb',
    'script_parts/run.rb'
  ]
  script_src = Dir[*script_files].map { |file| File.read(file) }.join("\n")

  File.open('avsh', 'w') do |file|
    file.write(script_src)
    file.chmod(0755)
  end
end
