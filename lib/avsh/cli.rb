module Avsh
  # Glue code to extract config options from the environment and then hook
  # everything up
  class CLI
    def initialize(environment, host_directory)
      @logger = Avsh::Logger.new(environment.include?('AVSH_DEBUG'))
      # See https://www.vagrantup.com/docs/other/environmental-variables.html
      @vagrant_cwd = environment.fetch('VAGRANT_CWD', host_directory)
      @vagrantfile_name = environment.fetch('VAGRANT_VAGRANTFILE', nil)
      @host_directory = host_directory
    end

    def execute(command)
      reader = VagrantfileReader.new(@logger, @vagrant_cwd, @vagrantfile_name)
      matcher = SyncedFolderMatcher.new(@logger, @vagrant_cwd,
                                        reader.find_synced_folders_by_machine)
      machine_name, guest_dir = matcher.match(reader.find_primary,
                                              @host_directory)

      multiplex_manager = SshMultiplexManager.new(@logger, machine_name,
                                                  @vagrant_cwd)
      executor = SshCommandExecutor.new(logger, machine_name, multiplex_manager)
      executor.execute(guest_dir, command)
    end
  end
end
