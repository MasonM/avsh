module Avsh
	class VagrantfileReader
		# This module and VagrantfileEnvironment are a horrible hack to parse out the synced_folder
		# declarations from a Vagrantfile, without incurring the overhead of loading Vagrant. It uses
		# a binding object to eval the Vagrantfile in VagrantfileEnvironment, which will communicate
		# with a dummy Vagrant module.

		def initialize(logger, vagrantfile_dir)
			@logger = logger
			@vagrantfile_path = find_vagrantfile(vagrantfile_dir)
		end

		def find_synced_folders(vm_name)
			# Eval the Vagrantfile with this module as the execution context
			@logger.debug "Parsing Vagrantfile '#{@vagrantfile_path}' ..."

			begin
				config = VagrantfileEnvironment.evaluate(@vagrantfile_path, vm_name)
			rescue Exception => e
				@logger.error("avsh got an unexpected error while reading the Vagrantfile at #{@vagrantfile_path}:\n#{e.inspect}")
				exit 1
			end

			@logger.debug "Got synced folders: #{config.synced_folders}"
			config.synced_folders
		end

		private

		def find_vagrantfile(vagrantfile_dir)
			# Vagrant allows the Vagrantfile to be stored as "vagrantfile", so we have to check for both.
			for filename in ['Vagrantfile', 'vagrantfile']
				path = File.join(vagrantfile_dir, filename)
				return path if File.readable? path
			end
			@logger.error(
				"avsh couldn't find the Vagrantfile for the directory #{vagrantfile_dir}\n" +
				"This usually means you need to specify the AVSH_VAGRANTFILE_DIR configuration option. " +
				"See README.md for details."
			)
			exit 1
		end
	end
end
