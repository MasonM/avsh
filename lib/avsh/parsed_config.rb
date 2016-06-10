module Avsh
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
      default_folders = @synced_folders

      if !@synced_folders.value?('/vagrant') && !@synced_folders.key?('.')
        # Add default /vagrant share unless overriden
        default_folders['.'] = '/vagrant'
      end

      folders = {}
      folders['default'] = default_folders if @machines.empty?
      @machines.each do |name, config|
        folders[name] = default_folders.merge(config.synced_folders)
      end

      folders
    end
  end
end
