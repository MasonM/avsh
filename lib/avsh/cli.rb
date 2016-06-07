require 'optparse'

module Avsh
  # Simple class to extract config options from the environment and hook
  # everything up.
  class CLI
    def initialize(environment)
      # See https://www.vagrantup.com/docs/other/environmental-variables.html
      @vagrant_cwd = environment.fetch('VAGRANT_CWD', nil)
      @vagrantfile_name = environment.fetch('VAGRANT_VAGRANTFILE', nil)
    end

    # rubocop:disable Metrics/AbcSize
    def execute(host_directory, options, command)
      logger = Logger.new(options[:debug])
      reader = VagrantfileReader.new(logger, host_directory, @vagrant_cwd,
                                     @vagrantfile_name)

      matcher = MachineGuestDirMatcher.new(logger, reader.vagrantfile_path,
                                           reader.config)
      machine_name, guest_dir = matcher.match(host_directory, options[:machine])

      multiplex_manager = SshMultiplexManager.new(logger, machine_name,
                                                  reader.vagrantfile_path)
      multiplex_manager.initialize_socket_if_needed(options[:reconnect])

      executor = SshCommandExecutor.new(logger, machine_name,
                                        multiplex_manager.controlmaster_path)
      executor.execute(guest_dir, command.join(' '))
    end
  end
end
