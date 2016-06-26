require 'optparse'

module Avsh
  # Handles parsing ARGV to extract avsh options, ssh arguments, and the command
  # to run
  class ArgumentParser
    def parse(argv)
      @options = {
        machine: nil,
        debug: false,
        reconnect: false,
        ssh_options: '',
        command: nil
      }

      begin
        remaining_args = parser.order!(argv)
      rescue OptionParser::ParseError => e
        puts 'ERROR: ' + e.message + "\n\n" + parser.help
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

    private

    def vagrant_ssh_compatibility_mode(remaining_args)
      if @options[:machine] # rubocop:disable Style/GuardClause
        raise VagrantCompatibilityModeMachineError, @options
      elsif remaining_args.length > 1
        raise VagrantCompatibilityModeMultipleMachinesError
      end
      @options[:machine] = remaining_args[0]
      [@options, @options[:command]]
    end

    def parser # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      OptionParser.new do |opts|
        opts.banner = banner_usages + "\nOptions:"

        opts.on('-m', '--machine MACHINE', 'Target Vagrant machine(s).',
                'Can be specified as a plain string for a single machine, a',
                'comma-separated list for multiple machines, or a regular ',
                'expression in the form /search/ for one or more machines.',
                'If not given, will infer from the Vagrantfile. See README.md '\
                'for details.') do |machine|
          @options[:machine] = machine.strip
        end

        opts.on('-r', '--reconnect', 'Closes SSH multiplex socket if present' \
                ' and re-initializes it') do
          @options[:reconnect] = true
        end

        opts.on('-s', '--ssh-options OPTS', 'Additional options to pass ' \
                'to SSH, e.g. "-a -6"') do |ssh_options|
          @options[:ssh_options] = ssh_options.strip
        end

        opts.on('-d', '--debug', 'Verbosely print debugging info to STDOUT') do
          @options[:debug] = true
        end

        opts.on('-v', '--version', 'Display version') do
          puts "avsh v#{Avsh::VERSION}"
          exit
        end

        opts.on('-h', '--help', 'Display help') do
          puts opts.help
          exit
        end

        opts.on('-c', '--command COMMAND', 'Command to execute (only for ' \
                'compatibility with Vagrant SSH)') do |cmd|
          @options[:command] = cmd
        end
      end
    end

    def banner_usages
      lines = {
        'Usage: avsh [options] [--] COMMAND' => 'execute given command via SSH',
        '   or: avsh [options]' => 'start a login shell'
      }
      max_chars_left = lines.keys.map(&:length).max
      padding = 4
      lines.reduce('') do |memo, line|
        memo + line[0].ljust(max_chars_left + padding) + line[1] + "\n"
      end
    end
  end
end
