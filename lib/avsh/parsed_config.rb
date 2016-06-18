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
        { 'default' => @default_synced_folders }
      else
        folders = @machine_synced_folders.map do |name, synced_folders|
          [name, @default_synced_folders.merge(synced_folders)]
        end

        # Sort the primary machine to the top, since it should be matched first
        if @primary_machine
          folders.sort_by! { |f| f[0] == @primary_machine ? 0 : 1 }
        end

        Hash[folders]
      end
    end
  end
end
