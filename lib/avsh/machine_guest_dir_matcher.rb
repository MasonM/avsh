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
    def match(host_directory, machine_search_string = nil)
      real_host_directory = File.expand_path(host_directory)
      synced_folders_by_machine = @vagrant_config.collect_folders_by_machine

      if machine_search_string
        machines = @vagrant_config.match_machines!(machine_search_string)
        if machines.length > 1
          # Don't do synced folder matching for multiple machines, as that could
          # lead to unexpected results.
          Hash[machines.map { |machine| [machine, nil] }]
        else
          synced_folders = synced_folders_by_machine[machines[0]]
          match = match_synced_folder(real_host_directory, synced_folders)
          { machines[0] => match }
        end
      else
        match = match_machine_and_synced_folders(real_host_directory,
                                                 synced_folders_by_machine)
        match || default_fallback(real_host_directory)
      end
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
        return Hash[machine_name, guest_dir]
      end
      nil
    end

    def default_fallback(host_directory)
      default_machine = @vagrant_config.primary_machine ||
                        @vagrant_config.first_machine
      @logger.debug('Couldn\'t find guest directory for ' \
        "'#{host_directory}', falling back to #{default_machine} for " \
        'the machine and nothing for guest directory')
      { default_machine => nil }
    end

    def match_synced_folder(host_directory, folders)
      vagrantfile_dir = File.dirname(@vagrantfile_path)
      folders.each do |dest, src|
        real_src = File.expand_path(src, vagrantfile_dir)
        next unless host_directory.start_with?(real_src)
        relative_directory = host_directory[real_src.length..-1]
        full_directory = File.join(dest, relative_directory)
        return full_directory
      end
      nil
    end
  end
end
