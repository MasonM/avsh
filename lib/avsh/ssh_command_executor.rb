require 'open3'

module Avsh
	class SshCommandExecutor
		def initialize(vm_name, vagrantfile_dir)
			@vm_name = vm_name
			@vagrantfile_dir = vagrantfile_dir
		end

		def execute(guest_directory, command)
			if not File.socket?(ssh_controlmaster_path)
				initialize_master_socket
			end

			ssh_command = ["ssh", "-o ControlPath #{ssh_controlmaster_path}"]
			if command.empty?
				# No command, so run a login shell
				command = 'exec $SHELL -l'
				ssh_command.push('-t') # force TTY allocation
			end
			ssh_command.push(@vm_name, "cd #{guest_directory}; #{command}")

			debug "Executing '#{ssh_command}'"

			# Script execution ends here, since SSH will replace the current process.
			exec(*ssh_command)

			# Shouldn't be possible to get to this point, but check anyway
			STDERR.puts("avsh failed to pass control to SSH. Please file a bug at https://github.com/MasonM/avsh/issues")
			exit 1
		end

		private

		def ssh_controlmaster_path
			# Put the socket file in /tmp/, since that seems like the most portable option that doesn't
			# require any extra work from the user. This means the socket file will be lost on reboot, but
			# that just means there will be a minor delay as it re-establishes the socket the next time avsh
			# is run.
			#
			# Another option would be to use AVSH_VAGRANTFILE_DIR/.vagrant/, which is what vassh does, but Vagrant
			# manages that directory and I don't think it's safe to be storing foreign files there.
			"/tmp/avsh_#{@vm_name}_controlmaster.sock"
		end

		def read_vagrant_ssh_config
			# Runs "vagrant ssh-config" to get the SSH config, which is needed so we can establish a control
			# socket using SSH directly.
			#
			# The VAGRANT_CWD environment variable tells Vagrant to look for the Vagrantfile in that
			# directory. See https://www.vagrantup.com/docs/other/environmental-variables.html
			ssh_config_command = ["vagrant", "ssh-config", @vm_name]
			debug "Executing vagrant ssh-config command: #{ssh_config_command}"
			stdout, stderr, status = Open3.capture3({"VAGRANT_CWD" => @vagrantfile_dir}, *ssh_config_command)
			if not status.success? or not stderr.empty?
				human_readable_command = "VAGRANT_CWD=#{@vagrantfile_dir} #{ssh_config_command.join(' ')}"
				if not status.success?
					STDERR.puts(
						"avsh failed to determine the SSH configuration for the VM '#{@vm_name}'.\n"+
						"Are the AVSH_VAGRANTFILE_DIR and AVSH_VM_NAME settings correct? See README.md for details.\n\n" +
						"Details:\n" +
						"Command \"#{human_readable_command}\" exited with status #{status.exitstatus}\n" +
						"Vagrant output:\n#{stdout}#{stderr}"
					)
				else
					STDERR.puts("avsh got an unexpected error message from Vagrant while running \"#{human_readable_command}\": #{stderr}")
				end
				exit 1
			end
			debug "Got SSH config for #{@vm_name}: stdout"
			stdout
		end

		def initialize_master_socket
			debug "Establishing control socket for '#{@vm_name}' at '#{ssh_controlmaster_path}'"

			ssh_config = read_vagrant_ssh_config()
			# This is mostly based off
			# https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing#Manually_Establishing_Multiplexed_Connections
			ssh_cmd = [
				"ssh",
				# Force TTY allocation
				"-t", "-t",
				# Don't execute a command, just go in background immediately
				"-f", "-N",
				# Read the SSH config from stdin. Note that /dev/stdin isn't in the POSIX standard, but I
				# don't know of any modern Unix that doesn't have it.
				"-F/dev/stdin",
				# Persist socket indefinitely
				"-o ControlPersist yes",
				# Auto-connect
				"-o ControlMaster auto",
				# Path to control socket
				"-o ControlPath #{ssh_controlmaster_path}",
				# Hostname set in ssh_config
				"#{@vm_name}"
			]
			debug "Executing SSH command '#{ssh_cmd}'"
			Open3.popen3(*ssh_cmd) do |stdin, stdout, stderr, wait_threads|
				if stdin.closed?
					STDERR.puts("avsh failed to establish a SSH ControlMaster socket. Error from SSH: '#{stderr.read}'")
					exit 1
				end
				stdin.puts(ssh_config)
			end
		end
	end
end
