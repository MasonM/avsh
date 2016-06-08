require 'open3'

module Avsh
  # Manages SSH multiplexing
  class SshMultiplexManager
    def initialize(logger, machine_name, vagrantfile_path, vagrant_home)
      @logger = logger
      @machine_name = machine_name
      @vagrantfile_dir = File.dirname(vagrantfile_path)
      @vagrant_home = File.expand_path(vagrant_home)
    end

    def initialize_socket_if_needed(reconnect = false)
      close_ssh_socket if reconnect && File.socket?(controlmaster_path)
      initialize_socket unless File.socket?(controlmaster_path)
    end

    # Returns the path to the socket file for the multiplex connection.
    # We put the socket file in Vagrant's temp directory because that doesn't
    # require any extra work from the user. We don't want to put it in /tmp/,
    # because having the socket file be globally-readable could be a security
    # issue in certain environments (anyone who can access the socket can hijack
    # the connection).
    #
    # Currently, Vagrant doesn't clean out it's tmp directory, so we don't have
    # to worry about the socket disappearing, but that could change in the
    # future. If that happens, I'll probably have to add a config option to let
    # users specify the path.
    def controlmaster_path
      "#{@vagrant_home}/tmp/avsh_#{@machine_name}_controlmaster.sock"
    end

    private

    def initialize_socket
      @logger.debug("Establishing control socket for '#{@machine_name}' " \
        "at '#{controlmaster_path}'")

      ssh_config = read_vagrant_ssh_config

      @logger.debug "Executing SSH command '#{ssh_master_socket_cmd}'"

      Open3.popen3(*ssh_master_socket_cmd) do |stdin, _stdout, stderr, _|
        raise SshMasterSocketError, stderr.read if stdin.closed?
        stdin.puts(ssh_config)
        stdin.close
      end
    end

    def close_ssh_socket
      ssh_cmd = ['ssh', '-O', 'exit', "-o ControlPath #{controlmaster_path}",
                 @machine_name]
      @logger.debug "Closing SSH connection with command '#{ssh_cmd}'"
      stdout, stderr, status = Open3.capture3(*ssh_cmd)
      unless status.success?
        raise SshMultiplexCloseError.new(ssh_cmd.join(' '), status, stderr,
                                         stdout)
      end
    end

    # Runs "vagrant ssh-config" to get the SSH config, which is needed so we
    # can establish a control socket using SSH directly.
    def read_vagrant_ssh_config
      ssh_config_command = ['vagrant', 'ssh-config', @machine_name]
      @logger.debug('Executing vagrant ssh-config command: ' +
                    ssh_config_command.to_s)
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
        # Don't execute a command, just go in background immediately
        '-f', '-N',
        # Read the SSH config from stdin. Note that /dev/stdin isn't in the
        # POSIX standard, but I don't know of any modern Unix that doesn't have
        # it.
        '-F/dev/stdin',
        # Persist socket until it's been explicitly closed or idle for 3 hours.
        # This is a minor precaution against evil maid attacks, though I don't
        # know if that's actually a concern for anyone's Vagrant setup.
        '-o ControlPersist 3h',
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
