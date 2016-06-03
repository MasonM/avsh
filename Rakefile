require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :create_script do
	out = File.read('lib/script_header.rb')
	Dir['lib/avsh/*.rb'].each do |file|
		out += File.read(file)
	end
	out += File.read('lib/script_footer.rb')

	File.open('avsh', 'w') do |file|
		file.write(out)
		file.chmod(0755)
	end
end
