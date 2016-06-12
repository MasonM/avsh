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

    # Tries to match host directory against synced_folder declarations, then
    # falls back to the default
    def match(host_directory, desired_machine = nil)
      synced_folders_by_machine = @vagrant_config.collect_folders_by_machine
      real_host_directory = File.realpath(host_directory)

      if desired_machine
        unless @vagrant_config.machine?(desired_machine)
          raise MachineNotFoundError.new(desired_machine, @vagrantfile_path)
        end
        synced_folders = synced_folders_by_machine[desired_machine]
        guest_dir = match_synced_folder(real_host_directory, synced_folders)
        return [desired_machine, guest_dir] if guest_dir
      else
        match = match_machine_and_synced_folders(real_host_directory,
                                                 synced_folders_by_machine)
        return match if match
      end
      default_fallback(real_host_directory, desired_machine)
    end

    private

    def match_machine_and_synced_folders(host_directory,
                                         synced_folders_by_machine)
      @logger.debug("Attempting to match '#{host_directory}' against " \
                    'synced folders: ' + synced_folders_by_machine.to_s)

      synced_folders_by_machine.each do |machine_name, synced_folders|
        guest_dir = match_synced_folder(host_directory, synced_folders)
        next unless guest_dir
        @logger.debug("Found guest path for '#{host_directory}' with " \
                      "machine '#{machine_name}' and directory " \
                      "'#{guest_dir}'")
        return machine_name, guest_dir
      end
      nil
    end

    def default_fallback(host_directory, desired_machine = nil)
      default_machine = desired_machine || @vagrant_config.primary_machine ||
                        @vagrant_config.first_machine
      @logger.debug('Couldn\'t find guest directory for ' \
        "'#{host_directory}', falling back to #{default_machine} for " \
        'the machine and nothing for guest directory (i.e. the vagrant home)')
      [default_machine, nil]
    end

    def match_synced_folder(host_directory, folders)
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
