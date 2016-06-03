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
			@logger.debug "Parsing Vagrantfile '#{@vagrantfile_path}' ..."

			# Raises VagrantfileEvalError on failure
			config = VagrantfileEnvironment.evaluate(@vagrantfile_path, vm_name)

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
			raise VagrantfileNotFoundError.new(vagrantfile_dir)
		end
	end
end
