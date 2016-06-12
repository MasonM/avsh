require 'pathname'

module Avsh
  # Finds full path for the Vagrantfile to use
  class VagrantfileFinder
    def initialize(vagrant_cwd = nil, vagrantfile_name = nil)
      @vagrant_cwd = vagrant_cwd
      @vagrantfile_name = vagrantfile_name
    end

    # Based off https://github.com/mitchellh/vagrant/blob/646414b347d4694de24693d226c35e42a88dea0e/lib/vagrant/environment.rb#L693
    def find(host_directory)
      start_directory = @vagrant_cwd || host_directory
      cur_directory = Pathname.new(start_directory)
      loop do
        filenames_to_check.each do |filename|
          path = cur_directory.join(filename)
          return path.to_s if path.readable?
        end
        break if cur_directory.root? || cur_directory.nil?
        cur_directory = cur_directory.parent
      end

      # Nothing found
      raise VagrantfileNotFoundError, start_directory
    end

    private

    def filenames_to_check
      if @vagrantfile_name
        [@vagrantfile_name]
      else
        # Defaults. Vagrant allows the Vagrantfile to be stored as
        # "vagrantfile", so we have to check for both.
        # See https://github.com/mitchellh/vagrant/blob/646414b347d4694de24693d226c35e42a88dea0e/lib/vagrant/environment.rb#L901
        %w(Vagrantfile vagrantfile)
      end
    end
  end
end
