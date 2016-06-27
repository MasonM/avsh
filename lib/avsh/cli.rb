module Avsh
  # Point of entry for avsh. Extracts environment variables, parses arguments,
  # and hooks everything up in execute_command()
  class CLI
    def initialize(environment)
      # See https://www.vagrantup.com/docs/other/environmental-variables.html
      @vagrant_cwd = environment.fetch('VAGRANT_CWD', nil)
      @vagrant_home = environment.fetch('VAGRANT_HOME', '~/.vagrant.d')
      @vagrantfile_name = environment.fetch('VAGRANT_VAGRANTFILE', nil)
    end

    def self.run
      # May exit here if "--help" or "--version" supplied
      options, command = ArgumentParser.new.parse(ARGV)

      new(ENV).execute_command(Dir.pwd, command, options)
    rescue Avsh::Error => e
      STDERR.puts(e.message)
      STDERR.puts(e.backtrace.join("\n")) if options && options[:debug]
      exit 1
    end

    def execute_command(host_directory, command, options)
      logger = DebugLogger.new(options[:debug])
      logger.debug "Executing command '#{command}' with options '#{options}'"

      finder = VagrantfileFinder.new(@vagrant_cwd, @vagrantfile_name)
      vagrantfile_path = finder.find(host_directory)

      loader = VagrantfileEnvironment::Loader.new(logger)
      config = loader.load_vagrantfile(vagrantfile_path)

      dispatcher = command_dispatcher(logger, vagrantfile_path, config)
      dispatcher.dispatch(host_directory, command, options)
    end

    private

    def command_dispatcher(logger, vagrantfile_path, config)
      matcher = MachineGuestDirMatcher.new(logger, vagrantfile_path, config)
      multiplex_manager = SshMultiplexManager.new(logger, vagrantfile_path,
                                                  @vagrant_home)
      CommandDispatcher.new(logger, multiplex_manager, matcher)
    end
  end
end
