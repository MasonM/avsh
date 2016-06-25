module Avsh
  # Executes a command on a machine using multiplex SSH
  class SshCommandExecutor
    def initialize(logger, machine_name, multiplex_manager)
      @logger = logger
      @machine_name = machine_name
      @multiplex_manager = multiplex_manager
    end

    def connect(reconnect = false)
      if reconnect && @multiplex_manager.active?(@machine_name)
        @multiplex_manager.close_socket(@machine_name)
      end
      unless @multiplex_manager.active?(@machine_name)
        @multiplex_manager.initialize_socket(@machine_name)
      end
    end

    def execute(command, guest_directory = nil, user_ssh_args = '')
      if command.empty?
        # No command, so run a login shell
        command = 'exec $SHELL -l'
      else
        # Set process name to the command so it appears as the window/tab title
        $PROGRAM_NAME = command
      end

      if guest_directory
        # Switch to guest directory before running command
        command = "cd #{guest_directory}; #{command}"
      end

      ssh_command = ['ssh'] + ssh_args(user_ssh_args) + [@machine_name, command]
      @logger.debug "Executing '#{ssh_command}'"

      # Script execution ends here, since SSH will replace the current process.
      Kernel.exec(*ssh_command)

      # Shouldn't be possible to get to this point
      raise ExecSshError
    end

    private

    def ssh_args(user_ssh_args)
      args = [@multiplex_manager.controlpath_option(@machine_name)]
      unless user_ssh_args.include?('-t') || user_ssh_args.include?('-T')
        # Default to TTY allocation, as that's what Vagrant does.
        # See https://github.com/mitchellh/vagrant/blob/fc1d2c29be6b19b9ee19c063e15f72283140ec8e/lib/vagrant/action/builtin/ssh_run.rb#L47
        args << '-t'
      end
      args += user_ssh_args.split(' ') unless user_ssh_args.empty?
      args
    end
  end
end
