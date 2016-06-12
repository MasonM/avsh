require 'optparse'

module Avsh
  # Handles parsing ARGV to extract avsh options, ssh arguments, and the command
  # to run
  class ArgumentParser
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def self.parse(argv)
      options = {
        machine: nil,
        debug: false,
        reconnect: false,
        ssh_args: []
      }
      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: avsh [options] [-- ssh_options] [command]'

        opts.on('-m', '--machine <machine>', 'Target Vagrant machine',
                '(if not given, will infer from Vagrantfile. See README.md ' \
                'for details.') do |machine|
          options[:machine] = machine.strip
        end

        opts.on('-r', '--reconnect', 'Re-initialize SSH connection') do
          options[:reconnect] = true
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

      # Taken from https://github.com/mitchellh/vagrant/blob/07389ffc04147a25083ae88481b9ed2c7b3892d3/plugins/commands/ssh/command.rb#L28
      # Parse out the extra args to send to SSH, which is everything after "--"
      split_index = argv.index('--')
      if split_index
        options[:ssh_args] = argv.drop(split_index + 1)
        argv = argv.take(split_index)
      end

      command = parser.order!(argv)
      { options: options, command: command }
    end
    # rubocop:enable all
  end
end
