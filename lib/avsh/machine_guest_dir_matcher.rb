module Avsh
  # Determines the machine to connect to and the guest directory to change to
  # after SSHing. This involves trying to translate the directory on the host to
  # a corresponding directory in one of the machines by matching against the
  # synced_folder declarations extracted from the Vagrantfile
  class MachineGuestDirMatcher
    def initialize(logger, vagrantfile_path, vagrant_config)
      @logger = logger
      @vagrantfile_path = vagrantfile_path
      @vagrant_config = vagrant_config
    end

    # First checks if the current directory is the Vagrantfile directory, then
    # tries to match against synced_folder declarations, then falls back to the
    # default
    def match(host_directory, desired_machine = nil)
      if desired_machine && !@vagrant_config.has_machine?(desired_machine)
        raise MachineNotFoundError.new(desired_machine, @vagrantfile_path)
      end

      default_machine = desired_machine || @vagrant_config.primary_machine ||
                        @vagrant_config.first_machine
      real_host_directory = File.realpath(host_directory)

      synced_folders = @vagrant_config.collect_folders_by_machine
      @logger.debug('Attempting to match against synced folders: ' +
                    synced_folders.to_s)

      synced_folders = synced_folders[desired_machine] if desired_machine
      guest_dir = nil
      match = synced_folders.find do |_, inner_folders|
        guest_dir = match_synced_folder(inner_folders, real_host_directory)
      end

      if guest_dir
        @logger.debug("Found guest path for '#{real_host_directory}' with machine " \
          "'#{match[0]}' and directory '#{guest_dir}'")
        return match[0], guest_dir
      end
      @logger.debug('Couldn\'t find guest directory for ' \
        "'#{real_host_directory}', falling back to #{default_machine} for " \
        'the machine and \'/vagrant\' for the guest directory')
      return [default_machine, '/vagrant']
    end

    private

    def match_synced_folder(folders, host_directory)
      vagrantfile_dir = File.dirname(@vagrantfile_path)
      folders.each do |src, dest|
        real_src = File.realpath(src, vagrantfile_dir)
        next unless host_directory.start_with?(real_src)
        relative_directory = host_directory[real_src.length..-1]
        full_directory = File.join(dest, relative_directory)
        return full_directory
      end
      nil
    end
  end
end
