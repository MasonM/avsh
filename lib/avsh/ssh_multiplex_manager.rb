require 'open3'

module Avsh
  # Manages SSH multiplexing
  class SshMultiplexManager
    def initialize(logger, machine_name, vagrantfile_dir)
      @logger = logger
      @machine_name = machine_name
      @vagrantfile_dir = vagrantfile_dir
    end

    def initialize_if_needed
      return unless File.socket?(controlmaster_path)
      @logger.debug("Establishing control socket for '#{@machine_name}' " \
        "at '#{controlmaster_path}'")

      ssh_config = read_vagrant_ssh_config
      @logger.debug "Executing SSH command '#{ssh_cmd}'"
      Open3.popen3(*ssh_master_socket_cmd) do |stdin, _stdout, stderr, _|
        raise SshMasterSocketError, stderr.read if stdin.closed?
        stdin.puts(ssh_config)
      end
    end

    # Returns the path to the socket file for the multiplex connection.
    # We put the socket file in /tmp/, since that seems like the most portable
    # option that doesn't require any extra work from the user. This means the
    # socket file will be lost on reboot, but that just means there will be a
    # minor delay as it re-establishes the socket the next time avsh is run.
    #
    # Another option would be to use VAGRANT_CWD/.vagrant/, which is
    # what vassh does, but Vagrant manages that directory and I don't think it's
    # safe to be storing foreign files there.
    def controlmaster_path
      "/tmp/avsh_#{@machine_name}_controlmaster.sock"
    end

    private

    # Runs "vagrant ssh-config" to get the SSH config, which is needed so we
    # can establish a control socket using SSH directly.
    # rubocop:disable Metrics/MethodLength
    def read_vagrant_ssh_config
      ssh_config_command = ['vagrant', 'ssh-config', @machine_name]
      @logger.debug('Executing vagrant ssh-config command: ' +
        ssh_config_command)
      stdout, stderr, status = Open3.capture3(
        { 'VAGRANT_CWD' => @vagrantfile_dir },
        *ssh_config_command
      )
      if !status.success? || !stderr.empty?
        human_readable_command =
          "VAGRANT_CWD=#{@vagrantfile_dir} " + ssh_config_command.join(' ')
        raise VagrantSshConfigError.new(@machine_name, human_readable_command,
                                        status, stderr, stdout)
      end
      @logger.debug "Got SSH config for #{@machine_name}: #{stdout}"
      stdout
    end

    # This is mostly based off
    # https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing
    def ssh_master_socket_cmd
      [
        'ssh',
        # Force TTY allocation
        '-t', '-t',
        # Don't execute a command, just go in background immediately
        '-f', '-N',
        # Read the SSH config from stdin. Note that /dev/stdin isn't in the
        # POSIX standard, but I don't know of any modern Unix that doesn't have
        # it.
        '-F/dev/stdin',
        # Persist socket indefinitely
        '-o ControlPersist yes',
        # Auto-connect
        '-o ControlMaster auto',
        # Path to control socket
        "-o ControlPath #{controlmaster_path}",
        # Hostname set in ssh_config
        @machine_name
      ]
    end
  end
end
