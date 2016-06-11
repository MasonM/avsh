module Avsh
  # This module is a horrible hack to parse out the relevant config details from
  # a Vagrantfile, without incurring the overhead of loading Vagrant.
  module VagrantfileEnvironment
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
      # rubocop:enable all

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
        @primary_machine = machine_name.to_s if is_primary

        machine_config = Configure.new
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
        Avsh::ParsedConfig.new(@synced_folders, @machines, @primary_machine)
      end
    end
  end
end
