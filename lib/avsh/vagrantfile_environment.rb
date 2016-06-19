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
      def self.vm
        @@fake_vm_config
      end

      def self.method_missing(*)
        DummyConfig
      end
    end

    def self.prep
      # The FakeVMConfig instance is used to collect the config details we care
      # about. It's set as a class variable because we need to access it after
      # the Vagrantfile is eval'd, and we can't tell the Vagrantfile to use a
      # specific instance of anything.
      FakeVagrantConfig.class_variable_set(:@@fake_vm_config, FakeVMConfig.new)
    end

    def self.parsed_config(vagrantfile_path)
      FakeVagrantConfig.vm.parsed_config(vagrantfile_path)
    end

    # Collects config details for vm definitions
    class FakeVMConfig
      def initialize
        @synced_folders = {}
        @machines = {}
        @primary_machine = nil
      end

      def synced_folder(src, dest, options = nil)
        # Hash by the guest directory because that's what Vagrant does:
        # https://github.com/mitchellh/vagrant/blob/v1.8.4/plugins/kernel_v2/config/vm.rb#L217
        @synced_folders[File.expand_path(dest)] = {
          host_path: File.expand_path(src),
          disabled: options && options.key?(:disabled)
        }
      end

      def define(machine_name, options = nil)
        @primary_machine = machine_name.to_s if options && options[:primary]

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

      def parsed_config(vagrantfile_path, parsed_config_class = ParsedConfig)
        machine_synced_folders = @machines.map do |machine_name, machine_config|
          [machine_name, machine_config.synced_folders]
        end
        global_synced_folders = @synced_folders.reject do |_, opts|
          opts[:disabled]
        end
        parsed_config_class.new(vagrantfile_path, global_synced_folders,
                                Hash[machine_synced_folders], @primary_machine)
      end

      protected

      attr_reader :synced_folders
    end
  end
end
