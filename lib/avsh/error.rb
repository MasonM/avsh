module Avsh
  class Error < StandardError
  end

  # Indicates failure to eval() a Vagrantfile
  class VagrantfileEvalError < Error
    def initialize(vagrantfile_path, e)
      super('avsh got an unexpected error while reading the Vagrantfile at ' +
        vagrantfile_path + ":\n" + e.inspect)
      set_backtrace e.backtrace
    end
  end

  # Indicates failure to find Vagrantfile
  class VagrantfileNotFoundError < Error
    def initialize(vagrantfile_dir)
      super('avsh couldn\'t find the Vagrantfile for the directory ' \
        "#{vagrantfile_dir}\n" \
        'This usually means you need to specify the VAGRANT_CWD ' \
        'configuration option. See README.md for details.'
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

  # Indicates failures to get SSH configuration from "vagrant ssh-config"
  # rubocop:disable Metrics/MethodLength
  class VagrantSshConfigError < Error
    def initialize(machine_name, command, status, stdout, stderr)
      if !status.success?
        super(
          'avsh failed to determine the SSH configuration for the machine ' \
          "'#{machine_name}'.\n" \
          'Is the VAGRANT_CWD setting correct? ' \
          "See README.md for details.\n\n" \
          "Details:\n" \
          "Command \"#{command}\" exited with status #{status.exitstatus}\n" \
          "Vagrant output:\n#{stdout}#{stderr}"
        )
      else
        super('avsh got an unexpected error message from Vagrant while ' \
          "running \"#{command}\": #{stderr}")
      end
    end
  end

  # Indicates failure to establish SSH master socket for multiplexing
  class SshMasterSocketError < Error
    def initialize(error)
      super('avsh failed to establish a SSH ControlMaster socket. ' \
        "Error from SSH: '#{error}'")
    end
  end
end
