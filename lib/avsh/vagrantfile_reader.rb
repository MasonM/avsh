module Avsh
  # This module and VagrantfileEnvironment are a horrible hack to parse out the
  # synced_folder declarations from a Vagrantfile, without incurring the
  # overhead of loading Vagrant. It uses a binding object to eval the
  # Vagrantfile in VagrantfileEnvironment, which will communicate with a dummy
  # Vagrant module.
  class VagrantfileReader
    def initialize(logger, vagrantfile_dir, vagrantfile_name = nil)
      @logger = logger
      @vagrantfile_path = find_vagrantfile(vagrantfile_dir, vagrantfile_name)
    end

    def primary_machine
      config.find_primary
    end

    def find_synced_folders_by_machine
      config.collect_folders_by_machine
    end

    private

    def config
      # Raises VagrantfileEvalError on failure
      @config ||= VagrantfileEnvironment.evaluate(@logger, @vagrantfile_path)
    end

    # rubocop:disable Metrics/MethodLength
    def find_vagrantfile(vagrantfile_dir, vagrantfile_name = nil)
      filenames_to_check =
        if vagrantfile_name
          [vagrantfile_name]
        else
          # Vagrant allows the Vagrantfile to be stored as "vagrantfile", so we
          # have to check for both.
          %w('Vagrantfile' 'vagrantfile')
        end

      filenames_to_check.each do |filename|
        path = File.join(vagrantfile_dir, filename)
        return path if File.readable? path
      end

      # Nothing found
      raise VagrantfileNotFoundError, vagrantfile_dir
    end
  end
end
