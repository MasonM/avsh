module Avsh
  # Finds full path for the Vagrantfile to use
  class VagrantfileFinder
    def initialize(logger, vagrant_cwd = nil, vagrantfile_name = nil)
      @logger = logger
      @vagrant_cwd = vagrant_cwd
      @vagrantfile_name = vagrantfile_name
    end

    def find(host_directory)
      filenames_to_check =
        if @vagrantfile_name
          [@vagrantfile_name]
        else
          # Vagrant allows the Vagrantfile to be stored as "vagrantfile", so we
          # have to check for both.
          %w(Vagrantfile vagrantfile)
        end

      cur_directory = @vagrant_cwd || host_directory
      loop do
        filenames_to_check.each do |filename|
          path = File.join(cur_directory, filename)
          return path if File.readable? path
        end
        break if cur_directory == '/'
        cur_directory = File.dirname(cur_directory)
      end

      # Nothing found
      raise VagrantfileNotFoundError, @vagrant_cwd
    end
  end
end
