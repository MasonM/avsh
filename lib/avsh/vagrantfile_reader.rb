module Avsh
  # This module and VagrantfileEnvironment are a horrible hack to parse out the
  # synced_folder declarations from a Vagrantfile, without incurring the
  # overhead of loading Vagrant. It uses a binding object to eval the
  # Vagrantfile in VagrantfileEnvironment, which will communicate with a dummy
  # Vagrant module.
  class VagrantfileReader
    attr_reader :vagrantfile_path

    def initialize(logger, host_directory, vagrant_cwd = nil,
                   vagrantfile_name = nil)
      @logger = logger
      @vagrantfile_path = find_vagrantfile(host_directory, vagrant_cwd,
                                           vagrantfile_name)
    end

    def config
      # Raises VagrantfileEvalError on failure
      @config ||= VagrantfileEnvironment.evaluate(@logger, @vagrantfile_path)
    end

    private

    def find_vagrantfile(host_directory, vagrant_cwd = nil,
                         vagrantfile_name = nil)
      filenames_to_check =
        if vagrantfile_name
          [vagrantfile_name]
        else
          # Vagrant allows the Vagrantfile to be stored as "vagrantfile", so we
          # have to check for both.
          %w(Vagrantfile vagrantfile)
        end

      cur_directory = vagrant_cwd || host_directory
      loop do
        filenames_to_check.each do |filename|
          path = File.join(cur_directory, filename)
          return path if File.readable? path
        end
        break if cur_directory == '/'
        cur_directory = File.dirname(cur_directory)
      end

      # Nothing found
      raise VagrantfileNotFoundError, vagrantfile_dir
    end
  end
end
