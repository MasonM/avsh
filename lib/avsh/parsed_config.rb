module Avsh
  # Encapsulates parsed config details from VagrantfileEnvironment
  class ParsedConfig
    attr_reader :primary_machine

    def initialize(default_synced_folders, machine_synced_folders,
                   primary_machine)
      @default_synced_folders = default_synced_folders.freeze
      @machine_synced_folders = machine_synced_folders.freeze
      @primary_machine = primary_machine
    end

    def machine?(machine_name)
      @machine_synced_folders.key?(machine_name)
    end

    def first_machine
      first = @machine_synced_folders.first
      first ? first[0] : 'default'
    end

    def collect_folders_by_machine
      if @machine_synced_folders.empty?
        folders = { 'default' => merge_with_defaults({}) }
      else
        folders = {}
        @machine_synced_folders.each do |name, synced_folders|
          folders[name] = merge_with_defaults(synced_folders)
        end
      end
      folders
    end

    private

    def merge_with_defaults(synced_folders)
      default_folders = @default_synced_folders.dup
      if !synced_folders.value?('/vagrant') && !synced_folders.key?('.')
        # Add default /vagrant share unless overriden
        default_folders = { '.' => '/vagrant' }.merge(default_folders)
      end
      default_folders.merge(synced_folders)
    end
  end
end
