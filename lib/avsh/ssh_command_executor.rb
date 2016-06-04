require 'open3'

module Avsh
  # Executes a command on a machine using multiplex SSH
  class SshCommandExecutor
    def initialize(logger, machine_name, ssh_multiplex_manager)
      @logger = logger
      @machine_name = machine_name
      @ssh_multiplex_manager = ssh_multiplex_manager
    end

    # rubocop:disable Metrics/MethodLength
    def execute(guest_directory, command)
      @ssh_multiplex_manager.initialize_if_needed

      ssh_command = [
        'ssh',
        '-o ControlPath ' + @ssh_multiplex_manager.controlmaster_path
      ]
      if command.empty?
        # No command, so run a login shell
        command = 'exec $SHELL -l'
        ssh_command.push('-t') # force TTY allocation
      end
      ssh_command.push(@machine_name, "cd #{guest_directory}; #{command}")

      @logger.debug "Executing '#{ssh_command}'"

      # Script execution ends here, since SSH will replace the current process.
      exec(*ssh_command)

      # Shouldn't be possible to get to this point
      raise ExecSshError
    end
  end
end
