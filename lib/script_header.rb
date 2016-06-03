#!/usr/bin/env ruby

# avsh v0.1
# Homepage: https://github.com/MasonM/avsh
# Bugs: https://github.com/MasonM/avsh/issues

#### START CONFIGURATION #####
optional_config_file_path = File.absolute_path("#{Dir.home}/.avsh_config.rb")
if File.exist?(optional_config_file_path)
   load(optional_config_file_path)
else
   # Name of the Vagrant VM in which to execute commands. Defaults to 'dev'.
   AVSH_VM_NAME = ENV.fetch('AVSH_VM_NAME', 'dev')

   # Directory containing the Vagrantfile for the above VM. Defaults to current directory.
   AVSH_VAGRANTFILE_DIR = ENV.fetch("AVSH_VAGRANTFILE_DIR", Dir.pwd)
end
#### END CONFIGURATION #####

# Enable debug output by prepending AVSH_DEBUG=1 to the command (e.g. 'AVSH_DEBUG=1 avsh ls')
def debug(msg)
	puts "#{caller[0]}: #{msg}" if ENV.include?('AVSH_DEBUG')
end
