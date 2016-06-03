module Avsh
	class Logger
		def initialize(debug_mode)
			@debug_mode = debug_mode
		end

		def debug(msg)
			puts "#{caller[0]}: #{msg}" if @debug_mode
		end
	end
end
