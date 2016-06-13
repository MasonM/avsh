require 'optparse'

module Avsh
  # Handles parsing ARGV to extract avsh options, ssh arguments, and the command
  # to run
  class ArgumentParser
    def parse(argv)
      @options = { machine: nil, debug: false, reconnect: false, ssh_args: '' }
      command = parser.order!(argv)
      [@options, command]
    end

    private

    # rubocop:disable Metrics/MethodLength
    def parser
      OptionParser.new do |opts|
        opts.banner = 'Usage: avsh [options] [--] [command]'

        opts.on('-m', '--machine <machine>', 'Target Vagrant machine',
                '(if not given, will infer from Vagrantfile. See README.md ' \
                'for details.') do |machine|
          @options[:machine] = machine.strip
        end

        opts.on('-r', '--reconnect', 'Re-initialize SSH connection') do
          @options[:reconnect] = true
        end

        opts.on('-s', '--ssh-args <args>', 'Additional arguments to pass ' \
                'to SSH') do |args|
          @options[:ssh_args] = args.strip
        end

        opts.on('-d', '--debug', 'Enable debugging mode') do
          @options[:debug] = true
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
    end
    # rubocop:enable all
  end
end
