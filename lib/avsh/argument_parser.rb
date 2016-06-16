require 'optparse'

module Avsh
  # Handles parsing ARGV to extract avsh options, ssh arguments, and the command
  # to run
  class ArgumentParser
    # rubocop:disable Metrics/MethodLength
    def parse(argv)
      @options = {
        machine: nil,
        debug: false,
        reconnect: false,
        ssh_args: '',
        command: nil
      }

      begin
        remaining_args = parser.order!(argv)
      rescue OptionParser::InvalidOption
        puts parser
        exit 1
      end

      # If the command was supplied via "-c" (as with Vagrant SSH), switch to
      # 'vagrant ssh' compatibility mode
      if @options[:command]
        vagrant_ssh_compatibility_mode(remaining_args)
      else
        [@options, remaining_args.join(' ')]
      end
    end
    # rubocop:enable all

    private

    def vagrant_ssh_compatibility_mode(remaining_args)
      raise VagrantCompatibilityModeMachineError, @options if @options[:machine]
      raise MultipleMachinesError if remaining_args.length > 1
      @options[:machine] = remaining_args[0]
      [@options, @options[:command]]
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def parser
      OptionParser.new do |opts|
        opts.banner = 'Usage: avsh [options] [--] [command]'

        opts.on('-m', '--machine MACHINE', 'Target Vagrant machine',
                '(if not given, will infer from Vagrantfile. See README.md ' \
                'for details.') do |machine|
          @options[:machine] = machine.strip
        end

        opts.on('-r', '--reconnect', 'Re-initialize SSH connection') do
          @options[:reconnect] = true
        end

        opts.on('-s', '--ssh-args ARGS', 'Additional arguments to pass ' \
                'to SSH, e.g. "-a -6"') do |args|
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

        opts.on('-c', '--command COMMAND', 'Command to execute (only for ' \
                'compatibility with Vagrant SSH)') do |cmd|
          @options[:command] = cmd
        end
      end
    end
    # rubocop:enable all
  end
end
