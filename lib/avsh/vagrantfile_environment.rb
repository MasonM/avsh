module Avsh
  # This module is a horrible hack to parse out the relevant config details from
  # a Vagrantfile, without incurring the overhead of loading Vagrant. It uses a
  # binding object to eval the Vagrantfile in this module, which will
  # communicate with the dummy Vagrant module below.
  module VagrantfileEnvironment
    def self.evaluate(logger, vagrantfile_path)
      # The dummy_configure object will be used to collect the config details.
      # We need to set it as a class variable on Vagrant, since we can't tell
      # the Vagrantfile to use a specific instance of Vagrant.
      dummy_configure = Configure.new
      Vagrant.class_variable_set(:@@configure, dummy_configure)

      logger.debug "Parsing Vagrantfile '#{vagrantfile_path}' ..."
      begin
        # Eval the Vagrantfile with this module as the execution context
        binding.eval(File.read(vagrantfile_path), vagrantfile_path)
      # rubocop:disable Lint/RescueException:
      rescue Exception => e
        # Re-raise with a more specific exception
        raise VagrantfileEvalError.new(vagrantfile_path, e)
      end
      logger.debug "Got config: #{dummy_configure}"

      dummy_configure
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
        # DummyVagrantEnvironment.find_synced_folders
        yield @@configure
      end

      def self.method_missing(*) end # ignore everything else
    end

    # Dummy Configure object to collect the config details.
    class Configure
      attr_reader :is_primary

      def initialize(machine_name = :global, is_primary = false)
        @machine_name = machine_name
        @synced_folders = {}
        @children = []
        @is_primary = is_primary
      end

      def synced_folder(src, dest, *_args)
        @synced_folders[src] = dest unless @synced_folders.include?(src)
      end

      def define(machine_name, options = nil)
        is_primary = options && options.fetch(:primary, false)
        config = Configure.new(machine_name, is_primary)
        @children.append(config)
        yield config
      end

      def find_primary
        @children.find(&:is_primary)
      end

      def collect_folders_by_machine
        folders_by_machine = { @machine_name => @synced_folders }
        @children.each do |child|
          folders_by_machine.merge!(child.collect_folders_by_machine)
        end
        folders_by_machine
      end

      # Ensure this object continues to be used when defining a multi-machine
      # setup, and ignore any other methods, since they don't matter.
      def method_missing(*)
        yield self if block_given?
        self
      end
    end
  end
end
