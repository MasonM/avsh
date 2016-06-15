require 'spec_helper'

describe Avsh::SshMultiplexManager do
  subject do
    described_class.new(double(debug: nil), 'machine1', '/Vagrantfile', '/foo')
  end

  let(:controlpath) { '/foo/tmp/avsh_machine1_controlmaster.sock' }

  let(:stub_socket) { allow(File).to receive(:socket?) }

  let(:stub_status_success) { double('status', success?: true) }

  let(:stub_status_failure) { double('status', success?: false, exitstatus: 2) }

  let(:stub_stdin) do
    double('stdin', closed?: false, close: true, puts: 'foo')
  end

  let(:mock_read_vagrant_ssh) do
    expect(Open3).to receive(:capture2e)
      .with({ 'VAGRANT_CWD' => '/' }, 'vagrant', 'ssh-config', 'machine1')
  end

  let(:mock_ssh_initialize) do
    expect(Open3).to receive(:popen3)
      .with('ssh', any_args, "-o ControlPath #{controlpath}", 'machine1')
  end

  context 'without reconnect or valid socket' do
    before { stub_socket.and_return(false) }

    context 'fails to read vagrant-ssh-config' do
      it 'raises exception' do
        mock_read_vagrant_ssh.and_return(['', stub_status_failure])

        expect { subject.initialize_socket_if_needed }
          .to raise_error(Avsh::VagrantSshConfigError)
      end
    end

    context 'successfully reads vagrant-ssh-config' do
      context 'fails to execute ssh' do
        it 'raises exception' do
          mock_read_vagrant_ssh.and_return(['', stub_status_success])

          mock_ssh_initialize
            .and_yield(double('stdin', closed?: true), double('stdout'),
                       double('stderr', read: 'foo'), double('wait_thr'))

          expect { subject.initialize_socket_if_needed }
            .to raise_error(Avsh::SshMasterSocketError)
        end
      end

      context 'successfully executes ssh' do
        it 'initializes socket' do
          mock_read_vagrant_ssh.and_return(['vagrant_out', stub_status_success])

          expect(stub_stdin).to receive(:puts).with('vagrant_out')

          mock_ssh_initialize.and_yield(stub_stdin, double('stdout'),
                                        double('stderr'), nil)

          subject.initialize_socket_if_needed
        end
      end
    end
  end

  context 'without reconnect and a valid socket' do
    before { stub_socket.and_return(true) }

    it 'doesn\'t do anything' do
      subject.initialize_socket_if_needed
    end
  end

  context 'with reconnect and a valid socket' do
    before { stub_socket.and_return(true, false) }

    let(:mock_close_socket) do
      expect(Open3).to receive(:capture2e)
        .with('ssh', '-O', 'exit', "-o ControlPath #{controlpath}", 'machine1')
    end

    context 'fails to close socket' do
      it 'raises an exception' do
        mock_close_socket.and_return(['', stub_status_failure])

        expect { subject.initialize_socket_if_needed(true) }
          .to raise_error(Avsh::SshMultiplexCloseError)
      end
    end

    context 'successfully closes socket' do
      it 'initializes new socket' do
        mock_close_socket.and_return(['', stub_status_success])

        mock_read_vagrant_ssh.and_return(['', stub_status_success])

        mock_ssh_initialize.and_yield(stub_stdin, double('stdout'),
                                      double('stderr'), nil)

        subject.initialize_socket_if_needed(true)
      end
    end
  end

  context 'with reconnect but without a valid socket' do
    before { stub_socket.and_return(false) }

    it 'initializes new socket' do
      mock_read_vagrant_ssh.and_return(['', stub_status_success])

      mock_ssh_initialize.and_yield(stub_stdin, double('stdout'),
                                    double('stderr'), nil)

      subject.initialize_socket_if_needed(true)
    end
  end
end
