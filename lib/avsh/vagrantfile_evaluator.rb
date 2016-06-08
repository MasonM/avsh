module Avsh
  # Uses module_eval to load the Vagrantfile in VagrantfileEnvironment, where it
  # will communicate with the dummy Vagrant module and Configure class.
  # We inject an instance of the Configure class into the Vagrant module so we
  # can collect the configuration details we care about.
  class VagrantfileEvaluator
    def initialize(logger)
      @logger = logger
    end

    def evaluate(vagrantfile_path)
      # The dummy_configure object will be used to collect the config details.
      # We need to set it as a class variable on Vagrant, since we can't tell
      # the Vagrantfile to use a specific instance of Vagrant.
      dummy_configure = VagrantfileEnvironment::Configure.new
      VagrantfileEnvironment::Vagrant.class_variable_set(:@@configure,
                                                         dummy_configure)

      @logger.debug "Parsing Vagrantfile '#{vagrantfile_path}' ..."
      begin
        # Eval the Vagrantfile inside VagrantfileEnvironment
        VagrantfileEnvironment.module_eval(File.read(vagrantfile_path),
                                           vagrantfile_path)
        # rubocop:disable Lint/RescueException
      rescue Exception => e
        # Re-raise with a more specific exception
        raise VagrantfileEvalError.new(vagrantfile_path, e)
      end

      dummy_configure.parsed_config
    end
  end
end
