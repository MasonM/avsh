require 'optparse'

module Avsh
  # Simple class to extract config options from the environment and hook
  # everything up.
  class CLI
    def initialize(environment)
      # See https://www.vagrantup.com/docs/other/environmental-variables.html
      @vagrant_cwd = environment.fetch('VAGRANT_CWD', nil)
      @vagrant_home = environment.fetch('VAGRANT_HOME', '~/.vagrant.d')
      @vagrantfile_name = environment.fetch('VAGRANT_VAGRANTFILE', nil)
    end

    # rubocop:disable Metrics/AbcSize
    def execute(host_directory, options, command)
      logger = Logger.new(options[:debug])

      finder = VagrantfileFinder.new(logger, @vagrant_cwd, @vagrantfile_name)
      vagrantfile_path = finder.find(host_directory)

      evaluator = VagrantfileEvaluator.new(logger)
      config = evaluator.evaluate(vagrantfile_path)

      matcher = MachineGuestDirMatcher.new(logger, vagrantfile_path, config)
      machine_name, guest_dir = matcher.match(host_directory, options[:machine])

      multiplex_manager = SshMultiplexManager.new(logger, machine_name,
                                                  vagrantfile_path,
                                                  @vagrant_home)
      multiplex_manager.initialize_socket_if_needed(options[:reconnect])

      executor = SshCommandExecutor.new(logger, machine_name,
                                        multiplex_manager.controlmaster_path)
      executor.execute(guest_dir, command.join(' '))
    end
  end
end
