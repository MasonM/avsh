module Avsh
  # Finds full path for the Vagrantfile to use
  class VagrantfileFinder
    def initialize(vagrant_cwd = nil, vagrantfile_name = nil)
      @vagrant_cwd = vagrant_cwd
      @vagrantfile_name = vagrantfile_name
    end

    # Based off https://github.com/mitchellh/vagrant/blob/646414b347d4694de24693d226c35e42a88dea0e/lib/vagrant/environment.rb#L693
    def find(host_directory)
      start_directory = File.expand_path(@vagrant_cwd || host_directory)
      cur_directory = start_directory
      filenames = filenames_to_check

      # Traverse up directory tree, checking each directory to see if it
      # contains a Vagrantfile. Stop after 1000 directories as that almost
      # certainly means there's an infinite loop bug.
      1000.times do
        filenames.each do |filename|
          path = File.join(cur_directory, filename)
          return path if File.readable?(path)
        end
        break if File.dirname(cur_directory) == cur_directory
        cur_directory = File.dirname(cur_directory)
      end

      # Nothing found
      raise VagrantfileNotFoundError, start_directory
    end

    private

    def filenames_to_check
      if @vagrantfile_name
        [File.expand_path(@vagrantfile_name)]
      else
        # Defaults. Vagrant allows the Vagrantfile to be stored as
        # "vagrantfile", so we have to check for both.
        # See https://github.com/mitchellh/vagrant/blob/646414b347d4694de24693d226c35e42a88dea0e/lib/vagrant/environment.rb#L901
        %w(Vagrantfile vagrantfile)
      end
    end
  end
end
