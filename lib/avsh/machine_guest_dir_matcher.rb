module Avsh
  # Determines the machine to connect to and the guest directory to change to
  # after SSHing. This involves trying to translate the directory on the host to
  # a corresponding directory in one of the machines by matching against the
  # synced_folder declarations extracted from the Vagrantfile
  class MachineGuestDirMatcher
    def initialize(logger, vagrantfile_dir, synced_folders_by_machine)
      @logger = logger
      @vagrantfile_dir = vagrantfile_dir
      @synced_folders_by_machine = synced_folders_by_machine
    end

    # First checks if the current directory is the Vagrantfile directory, then
    # tries to match against synced_folder declarations, then falls back to the
    # default
    def match(primary_machine, host_directory, desired_machine = nil)
      default_machine = desired_machine || primary_machine
      real_host_directory = File.realpath(host_directory)

      match_by_vagrantfile_dir(real_host_directory, default_machine) || \
        match_by_synced_folder(real_host_directory, desired_machine) || \
        default_fallback(real_host_directory, default_machine)
    end

    private

    def match_by_vagrantfile_dir(host_directory, default_machine)
      if host_directory == @vagrantfile_dir
        @logger.debug('Current directory is the Vagrantfile directory (' \
          "#{@vagrantfile_dir}), so use #{default_machine} as the machine " \
          'and \'/vagrant\' as the guest directory')
        return default_machine, '/vagrant'
      end
      nil
    end

    def match_by_synced_folder(host_directory, desired_machine)
      @logger.debug('Attempting to match against synced folders: ' +
                    @synced_folders_by_machine.to_s)

      machine_name = guest_dir = nil

      if desired_machine
        machine_name = desired_machine
        folders = @synced_folders_by_machine.fetch(desired_machine, {})
        guest_dir = match_synced_folder(host_directory, folders)
      else
        @synced_folders_by_machine.each do |inner_machine, inner_folders|
          machine_name = inner_machine
          guest_dir = match_synced_folder(inner_folders, host_directory)
          break if guest_dir
        end
      end

      if guest_dir
        @logger.debug("Found guest path for '#{host_directory}' with machine " \
          "#{machine_name} and directory '#{guest_dir}'")
        return machine_name, guest_dir
      end
      nil
    end

    def default_fallback(host_directory, default_machine)
      @logger.debug('Couldn\'t find guest directory for ' \
        "'#{host_directory}', falling back to #{default_machine} for " \
        'the machine and \'/vagrant\' for the guest directory')
      [default_machine, '/vagrant']
    end

    def match_synced_folder(folders, host_directory)
      folders.each do |src, dest|
        real_src = File.realpath(src, @vagrantfile_dir)
        next unless host_directory.start_with?(real_src)
        relative_directory = host_directory[real_src.length..-1]
        full_directory = File.join(dest, relative_directory)
        return full_directory
      end
      nil
    end
  end
end
