module Avsh
  # Translates a directory on the host to the corresponding directory in the
  # guest by matching against the synced_folder declarations extracted from the
  # Vagrantfile
  class SyncedFolderMatcher
    def initialize(logger, vagrantfile_dir, synced_folders_by_machine)
      @logger = logger
      @vagrantfile_dir = vagrantfile_dir
      @synced_folders_by_machine = synced_folders_by_machine
    end

    # Iterates over the synced_folders dictionary to see if the given directory
    # is a descendent of (or equal to) one of the src folders.
    # rubocop:disable Metrics/MethodLength
    def match(primary_machine, host_directory)
      real_host_directory = File.realpath(host_directory)
      if host_directory == @vagrantfile_dir
        @logger.debug('Current directory is the Vagrantfile directory (' \
          "#{@vagrantfile_dir}), so use #{primary_machine} as the machine " \
          'and \'/vagrant\' as the guest directory')
        return primary_machine, '/vagrant'
      end

      machine_name, guest_dir = match_synced_folder(real_host_directory)
      if guest_dir
        @logger.debug("Found guest path for '#{real_host_directory}' with " \
          "machine #{machine_name} and directory '#{guest_dir}'")
        return machine_name, guest_dir
      end

      @logger.debug('Couldn\'t find guest directory for ' \
        "'#{real_host_directory}', falling back to #{primary_machine} for " \
        'the machine and \'/vagrant\' for the guest directory')
      [primary_machine, '/vagrant']
    end

    private

    def match_synced_folder(host_directory)
      @synced_folders_by_machine.each do |machine_name, folders|
        folders.each do |src, dest|
          real_src = File.realpath(src, @vagrantfile_dir)
          next unless host_directory.start_with?(real_src)
          relative_directory = host_directory[real_src.length..-1]
          full_directory = File.join(dest, relative_directory)
          return machine_name, full_directory
        end
      end
    end
  end
end
