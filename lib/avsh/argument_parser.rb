require 'optparse'

module Avsh
  # Handles parsing ARGV to extract avsh options and the command to run
  class ArgumentParser
    # rubocop:disable Metrics/MethodLength
    def self.parse(argv)
      options = { machine: nil, debug: false }
      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: avsh [options] [command]'

        opts.on('-m', '--machine', 'Target Vagrant machine', '(if not ' \
                'given, will infer from Vagrantfile. See README.md for ' \
                'details.') do |machine|
          options[:machine] = machine
        end

        opts.on('-d', '--debug', 'Enable debugging mode') do
          options[:debug] = true
        end

        opts.on('-v', '--version', 'Display version') do
          puts "avsh v#{Avsh::VERSION}"
          exit
        end

        opts.on('-h', '--help', 'Displays help') do
          puts opts.help
          exit
        end
      end
      command = parser.order!(argv)
      [options, command]
    end
  end
end
