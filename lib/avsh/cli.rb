require 'optparse'

module Avsh
  # Glue code to extract config options from the environment, parse options from
  # ARGV, and then hook everything up
  class CLI
    def initialize(environment, host_directory)
      @host_directory = host_directory
      # See https://www.vagrantup.com/docs/other/environmental-variables.html
      @vagrant_cwd = environment.fetch('VAGRANT_CWD', host_directory)
      @vagrantfile_name = environment.fetch('VAGRANT_VAGRANTFILE', nil)
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def execute(argv)
      options, command = ArgumentParser.parse(argv)
      logger = Logger.new(options[:debug])

      reader = VagrantfileReader.new(logger, @vagrant_cwd, @vagrantfile_name)
      matcher = MachineGuestDirMatcher.new(logger, @vagrant_cwd,
                                           reader.synced_folders_by_machine)
      machine_name, guest_dir = matcher.match(reader.default_machine,
                                              @host_directory,
                                              options[:machine])

      multiplex_manager = SshMultiplexManager.new(logger, machine_name,
                                                  @vagrant_cwd)
      executor = SshCommandExecutor.new(logger, machine_name, multiplex_manager)
      executor.execute(guest_dir, command.join(' '))
    end
  end
end
