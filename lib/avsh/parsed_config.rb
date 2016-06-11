module Avsh
  # Encapsulates parsed config details from VagrantfileEnvironment
  class ParsedConfig
    attr_reader :primary_machine

    def initialize(synced_folders, machines, primary_machine)
      @synced_folders = synced_folders.freeze
      @machines = machines.freeze
      @primary_machine = primary_machine
    end

    def machine?(machine_name)
      @machines.key?(machine_name)
    end

    def first_machine
      first = @machines.first
      first ? first[0] : 'default'
    end

    def collect_folders_by_machine
      if @machines.empty?
        folders = { 'default' => merge_with_defaults({}) }
      else
        folders = {}
        @machines.each do |name, config|
          folders[name] = merge_with_defaults(config.synced_folders)
        end
      end
      folders
    end

    private

    def merge_with_defaults(synced_folders)
      default_folders = @synced_folders.dup
      if !synced_folders.value?('/vagrant') && !synced_folders.key?('.')
        # Add default /vagrant share unless overriden
        default_folders = { '.' => '/vagrant' }.merge(default_folders)
      end
      default_folders.merge(synced_folders)
    end
  end
end
