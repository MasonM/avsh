module Avsh
  # This module is a horrible hack to parse out the relevant config details from
  # a Vagrantfile, without incurring the overhead of loading Vagrant.
  module VagrantfileEnvironment
    # Fake Vagrant module that stubs out everything except what's needed to
    # extract config details.
    module Vagrant
      VERSION = '1.8.3'.freeze

      # rubocop:disable Style/PredicateName
      def self.has_plugin?(*)
        # Just lie and say we have the plugin, because a Vagrantfile that calls
        # this is probably doing dependency checking, and will terminate if this
        # doesn't return true. However, this could result in unwanted behavior
        # if the Vagrantfile does weird things like ensuring a plugin DOESN'T
        # exist. I can't think of any reason for doing that.
        true
      end
      # rubocop:enable all

      def self.configure(*)
        yield FakeVagrantConfig
      end

      def self.method_missing(*) end # ignore everything else
    end

    # Based on https://github.com/mitchellh/vagrant/blob/v1.8.4/lib/vagrant/config/v2/dummy_config.rb
    module DummyConfig
      def self.method_missing(*)
        DummyConfig
      end
    end

    # Fake Vagrant::Config module
    module FakeVagrantConfig
      # The FakeVMConfig instance is used to collect the config details we care
      # about. It's set as a class variable because we need to access it after
      # the Vagrantfile is eval'd, and we can't tell the Vagrantfile to use a
      # specific instance of anything.
      # rubocop:disable Style/ClassVars
      def self.vm
        @@fake_vm_config ||= FakeVMConfig.new
      end
      # rubocop:enable all

      def self.method_missing(*)
        DummyConfig
      end
    end

    def self.parsed_config
      FakeVagrantConfig.vm.parsed_config
    end

    # Collects config details for vm definitions
    class FakeVMConfig
      def initialize
        @synced_folders = { '.' => '/vagrant' }
        @machines = {}
        @primary_machine = nil
      end

      def synced_folder(src, dest, **opts)
        if opts[:disabled]
          @synced_folders.delete(src)
        else
          @synced_folders[src] = dest
        end
      end

      def define(machine_name, options = nil)
        is_primary = options && options.fetch(:primary, false)
        @primary_machine = machine_name.to_s if is_primary

        machine_config = FakeVMConfig.new
        @machines[machine_name.to_s] = machine_config
        yield machine_config
      end

      def vm
        self
      end

      def method_missing(*)
        DummyConfig
      end

      def parsed_config(parsed_config_class = ParsedConfig)
        machine_synced_folders = @machines.map do |machine_name, machine_config|
          [machine_name, machine_config.synced_folders]
        end
        parsed_config_class.new(@synced_folders, Hash[machine_synced_folders],
                                @primary_machine)
      end

      protected

      attr_reader :synced_folders
    end
  end
end
