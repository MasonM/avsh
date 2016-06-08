module Avsh
  # Finds full path for the Vagrantfile to use
  class VagrantfileFinder
    def initialize(logger, vagrant_cwd = nil, vagrantfile_name = nil)
      @logger = logger
      @vagrant_cwd = vagrant_cwd
      @vagrantfile_name = vagrantfile_name
    end

    # Based off https://github.com/mitchellh/vagrant/blob/646414b347d4694de24693d226c35e42a88dea0e/lib/vagrant/environment.rb#L693
    def find(host_directory)
      filenames_to_check = @vagrantfile_name ? [@vagrantfile_name] : []

      # Add defaults. Vagrant allows the Vagrantfile to be stored as
      # "vagrantfile", so we have to check for both. See https://github.com/mitchellh/vagrant/blob/646414b347d4694de24693d226c35e42a88dea0e/lib/vagrant/environment.rb#L901
      filenames_to_check ||= %w(Vagrantfile vagrantfile)

      cur_directory = Pathname.new(@vagrant_cwd || host_directory)
      loop do
        filenames_to_check.each do |filename|
          path = cur_directory.join(filename)
          return path if path.readable?
        end
        break if cur_directory.root? || cur_directory.nil?
        cur_directory = cur_directory.parent
      end

      # Nothing found
      raise VagrantfileNotFoundError, @vagrant_cwd
    end
  end
end
