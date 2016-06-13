module Avsh
  # Base error class for all avsh exceptions
  class Error < StandardError
  end

  # Indicates user supplied the "-c" (or "--command") and "-m" (or "--machine")
  # command at the same time. The "-c" option triggers Vagrant SSH compatibility
  # mode, and cannot be used with "-m".
  class VagrantCompatibilityModeMachineError < Error
    def initialize(options)
      fixed_command = "avsh -m #{options[:machine]} #{options[:command]}"
      super('Cannot specify both the command and machine as an option. ' \
            'Instead, just specify the machine as an option, like this:' \
            "\n#{fixed_command}")
    end
  end

  # Indicates user tried to specify multiple machines to run against
  class MultipleMachinesError < Error
    def initialize
      super('Cannot specify multiple machines to execute the command against.')
    end
  end

  # Indicates failure to eval() a Vagrantfile
  class VagrantfileEvalError < Error
    def initialize(vagrantfile_path, e)
      super('avsh got an unexpected error while reading the Vagrantfile at ' +
        vagrantfile_path + ":\n" + e.inspect)
      set_backtrace e.backtrace
    end
  end

  # Indicates user specified a machine with the "--machine" argument, but it
  # wasn't found in the Vagrantfile
  class MachineNotFoundError < Error
    def initialize(machine_name, vagrantfile_path)
      super("avsh could\'t find the machine named '#{machine_name}' in the " \
        "Vagrantfile located at '#{vagrantfile_path}'")
    end
  end

  # Indicates failure to find Vagrantfile
  class VagrantfileNotFoundError < Error
    def initialize(vagrantfile_dir)
      super('avsh couldn\'t find the Vagrantfile for the directory ' \
        "#{vagrantfile_dir}\n" \
        'This usually means you need to specify the VAGRANT_CWD ' \
        'environment variable. See README.md for details.'
      )
    end
  end

  # Indicates failures to replace current process with SSH via Kernel.exec()
  class ExecSshError < Error
    def initialize
      super('avsh failed to pass control to SSH. Please file a bug at ' \
        'https://github.com/MasonM/avsh/issues')
    end
  end

  # Indicates failure to close a multiplexed connection
  class SshMultiplexCloseError < Error
    def initialize(command, status, stdout, stderr)
      super(
        'avsh got an error while trying to close the SSH connection with the ' \
        "the command '#{command}'\nStatus: #{status}\n" \
        "Output: #{stdout}#{stderr}"
      )
    end
  end

  # Indicates failures to get SSH configuration from "vagrant ssh-config"
  class VagrantSshConfigError < Error
    def initialize(machine_name, command, status, stdout, stderr)
      super(
        'avsh failed to determine the SSH configuration for the machine ' \
        "'#{machine_name}'.\n" \
        'Is the VAGRANT_CWD setting correct? ' \
        "See README.md for details.\n\n" \
        "Details:\n" \
        "Command \"#{command}\" exited with status #{status.exitstatus}\n" \
        "Vagrant output:\n#{stdout}#{stderr}"
      )
    end
  end

  # Indicates pipe closed while trying to use OpenSSH to establish a SSH master
  # socket for multiplexing
  class SshMasterSocketError < Error
    def initialize(error)
      super('avsh failed to establish a SSH ControlMaster socket due to a ' \
            "broken pipe. Error from SSH: '#{error}'")
    end
  end
end
