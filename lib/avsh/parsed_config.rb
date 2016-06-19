module Avsh
  # Encapsulates parsed config details from VagrantfileEnvironment
  class ParsedConfig
    attr_reader :primary_machine

    # @param vagrantfile_path [String] The path to the Vagrantfile (used for
    #   synced folder path expansion with relative directories).
    # @param global_synced_folders [Hash] The globally-defined synced folders,
    #   with keys being the guest directory (destination) and values being the
    #   host directory (source).
    # @param machine_synced_folders [Hash] Hash of machine names to a hash of
    #   synced folders defined in that machine definition (potentially empty)
    # @param primary_machine [String] The name of the primary machine, if one
    #   was defined
    def initialize(vagrantfile_path, global_synced_folders,
                   machine_synced_folders, primary_machine)
      @vagrantfile_dir = File.dirname(vagrantfile_path)
      @global_synced_folders = global_synced_folders.freeze
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
        { 'default' => add_vagrant_default(@global_synced_folders.dup) }
      else
        folders = @machine_synced_folders.map do |name, synced_folders|
          [name, merge_with_globals(synced_folders)]
        end

        # Sort the primary machine to the top, since it should be matched first
        if @primary_machine
          folders.sort_by! { |f| f[0] == @primary_machine ? 0 : 1 }
        end

        Hash[folders]
      end
    end

    private

    def add_vagrant_default(synced_folders)
      # Add default /vagrant share (see https://github.com/mitchellh/vagrant/blob/v1.8.4/plugins/kernel_v2/config/vm.rb#L511)
      if !synced_folders.key?('/vagrant') &&
         !synced_folders.value?(@vagrantfile_dir)
        synced_folders['/vagrant'] = @vagrantfile_dir
      end
      synced_folders
    end

    def merge_with_globals(synced_folders)
      add_vagrant_default(@global_synced_folders.dup).tap do |merged|
        synced_folders.each do |guest_path, opts|
          if opts[:disabled]
            merged.delete(guest_path)
            next
          end
          merged.delete('/vagrant') if opts[:host_path] == @vagrantfile_dir
          merged[guest_path] = opts[:host_path]
        end
      end
    end
  end
end
