module Avsh
	class DirectoryTranslator
		# Translates a directory on the host to the corresponding directory in the guest by matching
		# against the synced_folder declarations extracted from the Vagrantfile

		def initialize(vagrantfile_dir, synced_folders)
			@vagrantfile_dir = vagrantfile_dir
			@synced_folders = synced_folders
		end

		def translate(host_directory)
			# Iterates over the synced_folders dictionary to see if the given directory
			# is a descendent of (or equal to) one of the src folders.

			real_host_directory = File.realpath(host_directory)
			if real_host_directory == @vagrantfile_dir
				debug "Current directory is the Vagrantfile directory (#{@vagrantfile_dir}), so use '/vagrant'"
				return '/vagrant'
			end

			@synced_folders.each do |src, dest|
				real_src = File.realpath(src, @vagrantfile_dir)
				if real_host_directory.start_with?(real_src)
					relative_directory = real_host_directory[real_src.length .. -1]
					full_directory = File.join(dest, relative_directory)
					debug "Guest path for '#{real_host_directory}' is '#{full_directory}'"
					return full_directory
				end
			end

			debug "Couldn't find guest directory for '#{real_host_directory}', falling back to /vagrant"
			return '/vagrant'
		end
	end
end
