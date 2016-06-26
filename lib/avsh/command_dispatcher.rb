module Avsh
  # Executes a command on a machine using multiplex SSH
  class CommandDispatcher
    def initialize(logger, multiplex_manager, matcher)
      @logger = logger
      @multiplex_manager = multiplex_manager
      @matcher = matcher
    end

    def dispatch(host_directory, command, options)
      matches = @matcher.match(host_directory, options[:machine])
      if matches.length > 1 && command.empty?
        raise NoCommandWithMultipleMachinesError
      end

      matches.each do |machine_name, guest_dir|
        executor = SshCommandExecutor.new(@logger, machine_name,
                                          @multiplex_manager)
        executor.connect(options[:reconnect])
        executor.execute(command, guest_dir, matches.length == 1,
                         options[:ssh_options])
      end
    end
  end
end
