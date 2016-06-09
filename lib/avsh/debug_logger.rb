module Avsh
  # Minimal logger to print messages to STDOUT when debug mode is enabled
  class DebugLogger
    def initialize(debug_mode)
      @debug_mode = debug_mode
    end

    def debug(msg)
      puts "#{caller[0]}: #{msg}" if @debug_mode
    end
  end
end
