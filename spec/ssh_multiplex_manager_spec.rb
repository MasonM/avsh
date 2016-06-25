require 'spec_helper'

describe Avsh::SshMultiplexManager do
  subject do
    described_class.new(double(debug: nil), '/Vagrantfile', '/foo')
  end

  let(:machine_name) { 'machine1' }
  let(:controlpath) { "/foo/tmp/avsh_#{machine_name}_controlmaster.sock" }
  let(:controlpath_option) { "-o ControlPath #{controlpath}" }
  let(:stub_status_success) { double('status', success?: true) }
  let(:stub_status_failure) { double('status', success?: false, exitstatus: 2) }

  context 'controlpath_path' do
    it 'returns ControlPath option for ssh' do
      expect(subject.controlpath_option(machine_name)).to eq controlpath_option
    end
  end

  context 'active?' do
    let(:stub_socket) { allow(File).to receive(:socket?) }

    it 'returns true only if controlpath is a socket' do
      stub_socket.with(controlpath).and_return(true, false)
      expect(subject.active?(machine_name)).to eq true
      expect(subject.active?(machine_name)).to eq false
    end
  end

  context 'initialize_socket' do
    let(:mock_read_vagrant_ssh) do
      expect(Open3).to receive(:capture2e)
        .with({ 'VAGRANT_CWD' => '/' }, 'vagrant', 'ssh-config', machine_name)
    end

    let(:mock_ssh_initialize) do
      expect(Open3).to receive(:popen3)
        .with('ssh', any_args, controlpath_option, machine_name)
    end

    context 'fails to read vagrant-ssh-config' do
      it 'raises exception' do
        mock_read_vagrant_ssh.and_return(['', stub_status_failure])

        expect { subject.initialize_socket(machine_name) }
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

          expect { subject.initialize_socket(machine_name) }
            .to raise_error(Avsh::SshMasterSocketError)
        end
      end

      context 'successfully executes ssh' do
        let(:stub_stdin) do
          double('stdin', closed?: false, close: true, puts: 'foo')
        end

        it 'initializes socket' do
          mock_read_vagrant_ssh.and_return(['vagrant_out', stub_status_success])

          expect(stub_stdin).to receive(:puts).with('vagrant_out')

          mock_ssh_initialize.and_yield(stub_stdin, double('stdout'),
                                        double('stderr'), nil)

          subject.initialize_socket(machine_name)
        end
      end
    end
  end

  context 'close_socket' do
    let(:mock_close_socket) do
      expect(Open3).to receive(:capture2e)
        .with('ssh', '-O', 'exit', controlpath_option, machine_name)
    end

    context 'fails to close socket' do
      it 'raises an exception' do
        mock_close_socket.and_return(['', stub_status_failure])

        expect { subject.close_socket(machine_name) }
          .to raise_error(Avsh::SshMultiplexCloseError)
      end
    end

    context 'successfully closes socket' do
      it 'initializes new socket' do
        mock_close_socket.and_return(['', stub_status_success])

        subject.close_socket(machine_name)
      end
    end
  end
end
