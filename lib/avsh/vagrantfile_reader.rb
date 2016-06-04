module Avsh
  # This module and VagrantfileEnvironment are a horrible hack to parse out the
  # synced_folder declarations from a Vagrantfile, without incurring the
  # overhead of loading Vagrant. It uses a binding object to eval the
  # Vagrantfile in VagrantfileEnvironment, which will communicate with a dummy
  # Vagrant module.
  class VagrantfileReader
    def initialize(logger, vagrantfile_dir)
      @logger = logger
      @vagrantfile_path = find_vagrantfile(vagrantfile_dir)
    end

    def find_synced_folders(vm_name)
      @logger.debug "Parsing Vagrantfile '#{@vagrantfile_path}' ..."

      # Raises VagrantfileEvalError on failure
      config = VagrantfileEnvironment.evaluate(@vagrantfile_path, vm_name)

      @logger.debug "Got synced folders: #{config.synced_folders}"
      config.synced_folders
    end

    private

    # Vagrant allows the Vagrantfile to be stored as "vagrantfile", so we have
    # to check for both.
    def find_vagrantfile(vagrantfile_dir)
      %w('Vagrantfile', 'vagrantfile').each do |filename|
        path = File.join(vagrantfile_dir, filename)
        return path if File.readable? path
      end

      # Nothing found
      raise VagrantfileNotFoundError, vagrantfile_dir
    end
  end
end
