module Avsh
  # This module is a horrible hack to parse out the relevant config details from
  # a Vagrantfile, without incurring the overhead of loading Vagrant.
  module VagrantfileEnvironment
    # Uses binding object to eval the Vagrantfile, which will communicate with
    # the dummy Vagrant module below.
    class Evaluator
      def initialize(logger)
        @logger = logger
      end

      def evaluate(vagrantfile_path)
        # The dummy_configure object will be used to collect the config details.
        # We need to set it as a class variable on Vagrant, since we can't tell
        # the Vagrantfile to use a specific instance of Vagrant.
        dummy_configure = Configure.new
        Vagrant.class_variable_set(:@@configure, dummy_configure)

        @logger.debug "Parsing Vagrantfile '#{vagrantfile_path}' ..."
        begin
          # Eval the Vagrantfile with this module as the execution context
          binding.eval(File.read(vagrantfile_path), vagrantfile_path)
        # rubocop:disable Lint/RescueException
        rescue Exception => e
          # Re-raise with a more specific exception
          raise VagrantfileEvalError.new(vagrantfile_path, e)
        end

        dummy_configure.parsed_config
      end
    end

    # Dummy Vagrant module that stubs out everything except what's needed to
    # extract config details.
    module Vagrant
      # rubocop:disable Style/PredicateName
      def self.has_plugin?(*)
        # Just lie and say we have the plugin, because a Vagrantfile that calls
        # this is probably doing dependency checking, and will terminate if this
        # doesn't return true. However, this could result in unwanted behavior
        # if the Vagrantfile does weird things like ensuring a plugin DOESN'T
        # exist. I've never seen that before, though.
        true
      end

      def self.configure(*)
        # Give the provided block the dummy_configure object set above in
        # DummyVagrantEnvironment.evaluate
        yield @@configure
      end

      def self.method_missing(*) end # ignore everything else
    end

    # Dummy Configure object to collect the config details.
    class Configure
      attr_reader :synced_folders

      def initialize
        @synced_folders = {}
        @machines = {}
        @primary_machine = nil
      end

      def synced_folder(src, dest, *_args)
        @synced_folders[src] = dest unless @synced_folders.include?(src)
      end

      def define(machine_name, options = nil)
        is_primary = options && options.fetch(:primary, false)
        machine_config = Configure.new
        @primary_machine = machine_name.to_s if is_primary
        @machines[machine_name.to_s] = machine_config
        yield machine_config
      end

      # Ensure this object continues to be used when defining a multi-machine
      # setup, and ignore any other methods, since they don't matter.
      def method_missing(*)
        yield self if block_given?
        self
      end

      def parsed_config
        ParsedConfig.new(@synced_folders, @machines, @primary_machine)
      end
    end

    # Encapsulates parsed config details and operations on them
    class ParsedConfig
      attr_reader :primary_machine

      def initialize(synced_folders, machines, primary_machine)
        @synced_folders = synced_folders
        @machines = machines
        @primary_machine = primary_machine
      end

      def has_machine?(machine_name)
        @machines.include?(machine_name)
      end

      def first_machine
        first = @machines.first
        first ? first[0] : 'default'
      end

      def collect_folders_by_machine
        folders = { 'default' => @synced_folders }

        if !@synced_folders.value?('/vagrant') && !@synced_folders.key?('.')
          # Add default /vagrant share unless overriden
          folders['default']['.'] = '/vagrant'
        end

        @machines.each do |name, config|
          folders[name] = config.synced_folders
        end
        folders
      end
    end
  end
end
