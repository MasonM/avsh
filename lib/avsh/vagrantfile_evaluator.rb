module Avsh
  # Uses module_eval to load the Vagrantfile in VagrantfileEnvironment, where it
  # will communicate with the fake Vagrant module
  class VagrantfileEvaluator
    def initialize(logger, environment = VagrantfileEnvironment)
      @logger = logger
      @environment = environment
    end

    def evaluate(vagrantfile_path)
      @logger.debug "Parsing Vagrantfile '#{vagrantfile_path}'"
      @environment.prep(File.dirname(vagrantfile_path))

      begin
        # Eval the Vagrantfile inside VagrantfileEnvironment
        @environment.module_eval(File.read(vagrantfile_path), vagrantfile_path)
      rescue ScriptError, StandardError => e
        # Re-raise with a more specific exception
        raise VagrantfileEvalError.new(vagrantfile_path, e)
      end

      @environment.parsed_config
    end
  end
end
