require 'optparse'

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
      args = ArgumentParser.parse(ARGV)

      new(ENV).execute_command(Dir.pwd, args[:command], args[:options])
    rescue Avsh::Error => e
      STDERR.puts(e.message)
      STDERR.puts(e.backtrace.join("\n")) if args && args[:options][:debug]
      exit 1
    end

    # rubocop:disable Metrics/AbcSize
    def execute_command(host_directory, command, options)
      logger = Logger.new(options[:debug])

      finder = VagrantfileFinder.new(@vagrant_cwd, @vagrantfile_name)
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
