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
  class VagrantCompatibilityModeMultipleMachinesError < Error
    def initialize
      super('Cannot specify multiple machines to execute a command against ' \
            'using the "-c" flag.')
    end
  end

  # Indicates user specified an invalid regexp for the "--machine" option
  class MachineRegexpError < Error
    def initialize(e)
      super('avsh got an error parsing the regexp given for the "--machine" ' \
        ":\n" + e.inspect)
      set_backtrace e.backtrace
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

  # Indicates user specified machine with the "--machine" option, but it
  # wasn't found in the Vagrantfile
  class MachineNotFoundError < Error
    def initialize(machine_name, vagrantfile_dir)
      super("avsh could\'t find the machine named '#{machine_name}' in the " \
        "Vagrantfile located at '#{vagrantfile_dir}'")
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

  # Indicates user specified multiple machines, but no command
  class NoCommandWithMultipleMachinesError < Error
    def initialize
      super('Multiple machines were specified via the --machine option, but ' \
            'no command was given. Omitting the command normally starts a ' \
            'login shell, but that I don\'t know which machine to use.')
    end
  end

  # Indicates failures to replace current process with SSH via Kernel.exec()
  class ExecSshError < Error
    def initialize
      super('avsh failed to pass control to SSH. Please file a bug at ' \
        'https://github.com/MasonM/avsh/issues if you\'re on one of the ' \
        'supported platforms.')
    end
  end

  # Indicates failures to execute a SSH command in a subshell via
  # Kernel.system()
  class SubshellSshError < Error
    def initialize(command, machine_name, exit_status)
      super("avsh got an error while executing the command '#{command}' on " \
            "the machine '#{machine_name}'\nExit status: #{exit_status}")
    end
  end

  # Indicates failure to close a multiplexed connection
  class SshMultiplexCloseError < Error
    def initialize(command, status, stdout_and_stderr)
      super(
        'avsh got an error while trying to close the SSH connection with the ' \
        "the command '#{command}'\n" \
        "Status: #{status}\n" \
        "Output: #{stdout_and_stderr}"
      )
    end
  end

  # Indicates failures to get SSH configuration from "vagrant ssh-config"
  class VagrantSshConfigError < Error
    def initialize(machine_name, command, status, stdout_and_stderr)
      msg = 'avsh failed to determine the SSH configuration for the machine ' \
        "'#{machine_name}'.\n"
      if stdout_and_stderr.include?('not yet ready for SSH')
        # Check if Vagrant says the VM is not ready, since that means
        # VAGRANT_CWD is correct, but the machine potentially isn't. This won't
        # work in non-English locales, since the exact error message is
        # locale-specific. It'd be possible to have it work in other locales by
        # passing the '--machine-readable' flag to 'vagrant ssh-config' and
        # checking for 'Vagrant::Errors::SSHNotReady' in the output, but
        # '--machine-readable' is an experimental feature that's subject to
        # change according to https://www.vagrantup.com/docs/cli/machine-readable.html
        msg += 'Use the --machine flag to specify a different machine.'
      else
        msg += 'Is the VAGRANT_CWD setting correct? See README.md for details.'
      end
      super(msg +
        "\n\nDetails:\n" \
        "Command \"#{command}\" exited with status #{status.exitstatus}\n" \
        "Vagrant output:\n#{stdout_and_stderr}"
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
