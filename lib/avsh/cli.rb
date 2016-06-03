module Avsh
	class CLI
		def initialize(logger, vagrantfile_dir, vm_name)
			@logger = logger
			@vagrantfile_dir = vagrantfile_dir
			@vm_name = vm_name
		end

		def execute(host_directory, command)
			reader = VagrantfileReader.new(@logger, @vagrantfile_dir)
			synced_folders = reader.find_synced_folders(@vm_name)

			directory_translator = DirectoryTranslator.new(@logger, @vagrantfile_dir, synced_folders)
			guest_dir = directory_translator.translate(host_directory)

			executor = SshCommandExecutor.new(@logger, @vm_name, @vagrantfile_dir)
			executor.execute(guest_dir, command)
		end
	end
end

