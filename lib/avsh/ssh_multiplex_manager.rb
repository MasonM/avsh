require 'open3'

module Avsh
  # Manages SSH multiplexing
  class SshMultiplexManager
    def initialize(logger, vagrantfile_path, vagrant_home)
      @logger = logger
      @vagrantfile_dir = File.dirname(vagrantfile_path)
      @vagrant_home = File.expand_path(vagrant_home)
    end

    def controlpath_option(machine_name)
      "-o ControlPath #{controlmaster_path(machine_name)}"
    end

    def active?(machine_name)
      File.socket?(controlmaster_path(machine_name))
    end

    def initialize_socket(machine_name)
      @logger.debug("Establishing control socket for '#{machine_name}' " \
                    "at '#{controlmaster_path(machine_name)}'")

      ssh_config = read_vagrant_ssh_config(machine_name)
      command = ssh_master_socket_cmd(machine_name)

      @logger.debug "Executing SSH command '#{command}'"
      Open3.popen3(*command) do |stdin, _stdout, stderr, _|
        raise SshMasterSocketError, stderr.read if stdin.closed?
        stdin.puts(ssh_config)
        stdin.close
      end
    end

    def close_socket(machine_name)
      ssh_cmd = [
        'ssh',
        '-O', 'exit',
        controlpath_option(machine_name),
        machine_name
      ]
      @logger.debug "Closing SSH connection with command '#{ssh_cmd}'"
      stdout_and_stderr, status = Open3.capture2e(*ssh_cmd)
      unless status.success?
        raise SshMultiplexCloseError.new(ssh_cmd.join(' '), status,
                                         stdout_and_stderr)
      end
    end

    private

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
    def controlmaster_path(machine_name)
      "#{@vagrant_home}/tmp/avsh_#{machine_name}_controlmaster.sock"
    end

    # Runs "vagrant ssh-config" to get the SSH config, which is needed so we
    # can establish a control socket using SSH directly.
    def read_vagrant_ssh_config(machine_name)
      ssh_config_command = ['vagrant', 'ssh-config', machine_name]
      @logger.debug('Executing vagrant ssh-config command: ' +
                    ssh_config_command.to_s)
      stdout_and_stderr, status = Open3.capture2e(
        { 'VAGRANT_CWD' => @vagrantfile_dir },
        *ssh_config_command
      )
      unless status.success?
        human_readable_command =
          "VAGRANT_CWD=#{@vagrantfile_dir} " + ssh_config_command.join(' ')
        raise VagrantSshConfigError.new(machine_name, human_readable_command,
                                        status, stdout_and_stderr)
      end
      @logger.debug "Got SSH config for #{machine_name}: #{stdout_and_stderr}"
      stdout_and_stderr
    end

    def ssh_master_socket_cmd(machine_name)
      [
        'ssh',
        # Don't execute a command
        '-N',
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
        controlpath_option(machine_name),
        # This is the hostname returned by "vagrant ssh-config"
        machine_name
      ]
    end
  end
end
