module Avsh
  # Translates a directory on the host to the corresponding directory in the
  # guest by matching against the synced_folder declarations extracted from the
  # Vagrantfile
  class DirectoryTranslator
    def initialize(logger, vagrantfile_dir, synced_folders)
      @logger = logger
      @vagrantfile_dir = vagrantfile_dir
      @synced_folders = synced_folders
    end

    # Iterates over the synced_folders dictionary to see if the given directory
    # is a descendent of (or equal to) one of the src folders.
    # rubocop:disable Metrics/MethodLength
    def translate(host_directory)
      real_host_directory = File.realpath(host_directory)
      if host_directory == @vagrantfile_dir
        @logger.debug('Current directory is the Vagrantfile directory (' \
          "#{@vagrantfile_dir}), so use '/vagrant'")
        return '/vagrant'
      end

      guest_dir = match_synced_folder(real_host_directory)
      if guest_dir
        @logger.debug("Guest path for '#{real_host_directory}' is " \
          "'#{guest_dir}'")
        return guest_dir
      end

      @logger.debug('Couldn\'t find guest directory for ' \
        "'#{real_host_directory}', falling back to /vagrant")
      '/vagrant'
    end

    private

    def match_synced_folder(host_directory)
      @synced_folders.each do |src, dest|
        real_src = File.realpath(src, @vagrantfile_dir)
        next unless host_directory.start_with?(real_src)
        relative_directory = host_directory[real_src.length..-1]
        full_directory = File.join(dest, relative_directory)
        return full_directory
      end
    end
  end
end
