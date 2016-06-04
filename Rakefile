require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :script do
  out = File.read('script_parts/shebang.sh')
  out += File.read('script_parts/config.rb')
  Dir['lib/avsh/*.rb'].each do |file|
    out += File.read(file)
  end
  out += File.read('script_parts/run.rb')

  File.open('avsh', 'w') do |file|
    file.write(out)
    file.chmod(0755)
  end
end
