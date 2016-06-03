module Avsh
	class Error < StandardError
	end

	class VagrantfileEvalError < Error
		def initialize(vagrantfile_path, e)
			super "avsh got an unexpected error while reading the Vagrantfile at #{vagrantfile_path}:\n#{e.inspect}"
			set_backtrace e.backtrace
		end
	end

	class VagrantfileNotFoundError < Error
		def initialize(vagrantfile_dir)
			super(
				"avsh couldn't find the Vagrantfile for the directory #{vagrantfile_dir}\n" +
				"This usually means you need to specify the AVSH_VAGRANTFILE_DIR configuration option. " +
				"See README.md for details."
			)
		end
	end

	class ExecSshError < Error
		def initialize
			super("avsh failed to pass control to SSH. Please file a bug at https://github.com/MasonM/avsh/issues")
		end
	end

	class VagrantSshConfigError < Error
		def initialize(vm_name, command, status, stdout, stderr)
			if not status.success?
				super(
					"avsh failed to determine the SSH configuration for the VM '#{vm_name}'.\n"+
					"Are the AVSH_VAGRANTFILE_DIR and AVSH_VM_NAME settings correct? See README.md for details.\n\n" +
					"Details:\n" +
					"Command \"#{command}\" exited with status #{status.exitstatus}\n" +
					"Vagrant output:\n#{stdout}#{stderr}"
				)
			else
				super("avsh got an unexpected error message from Vagrant while running \"#{command}\": #{stderr}")
			end
		end
	end

	class SshMasterSocketError < Error
		def initialize(error)
			super("avsh failed to establish a SSH ControlMaster socket. Error from SSH: '#{error}'")
		end
	end
end
