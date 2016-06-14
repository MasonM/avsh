require 'spec_helper'

describe Avsh::SshMultiplexManager do
  subject do
    described_class.new(double(debug: nil), 'machine1', '/Vagrantfile', '/foo')
  end

  context 'without reconnect or valid socket' do
    before { allow(File).to receive(:socket?).and_return(false) }

    context 'fails to read vagrant-ssh-config' do
      it 'raises exception' do
        stub_status = double('status', success?: false, exitstatus: 2)
        expect(Open3).to receive(:capture2e).and_return(['', stub_status])

        expect { subject.initialize_socket_if_needed }
          .to raise_error(Avsh::VagrantSshConfigError)
      end
    end

    context 'successfully reads vagrant-ssh-config' do
      context 'fails to execute ssh' do
        it 'raises exception' do
          expect(Open3).to receive(:capture2e)
            .and_return(['', double('status', success?: true)])

          expect(Open3).to receive(:popen3)
            .and_yield(double('stdin', closed?: true), double('stdout'),
                       double('stderr', read: 'foo'), double('wait_thr'))

          expect { subject.initialize_socket_if_needed }
            .to raise_error(Avsh::SshMasterSocketError)
        end
      end

      context 'successfully executes ssh' do
        it 'initializes socket' do
          expect(Open3).to receive(:capture2e)
            .with({ 'VAGRANT_CWD' => '/' }, 'vagrant', 'ssh-config', 'machine1')
            .and_return(['vagrant_out', double('status', success?: true)])

          mock_stdin = double('stdin', closed?: false, close: true)
          expect(mock_stdin).to receive(:puts).with('vagrant_out')

          expect(Open3).to receive(:popen3).with('ssh', any_args, 'machine1')
            .and_yield(mock_stdin, double('stdout'), double('stderr'), nil)

          subject.initialize_socket_if_needed
        end
      end
    end
  end

  context 'without reconnect and a valid socket' do
    before { allow(File).to receive(:socket?).and_return(true) }

    it 'doesn\'t do anything' do
      subject.initialize_socket_if_needed
    end
  end

  context 'with reconnect and a valid socket' do
    before { allow(File).to receive(:socket?).and_return(true, false) }

    context 'fails to close socket' do
      it 'raises an exception' do
        expect(Open3).to receive(:capture2e)
          .and_return(['', double('status', success?: false)])
        expect { subject.initialize_socket_if_needed(true) }
          .to raise_error(Avsh::SshMultiplexCloseError)
      end
    end

    context 'successfully closes socket' do
      it 'initializes new socket' do
        stub_capture2e_return = ['', double('status', success?: true)]

        expect(Open3).to receive(:capture2e)
          .with('ssh', '-O', 'exit',
                '-o ControlPath /foo/tmp/avsh_machine1_controlmaster.sock',
                'machine1')
          .and_return(stub_capture2e_return)

        expect(Open3).to receive(:capture2e)
          .with({ 'VAGRANT_CWD' => '/' }, 'vagrant', 'ssh-config', 'machine1')
          .and_return(stub_capture2e_return)

        subject.initialize_socket_if_needed(true)
      end
    end
  end

  context 'with reconnect but without a valid socket' do
    before { allow(File).to receive(:socket?).and_return(false) }

    it 'initializes new socket' do
      expect(Open3).to receive(:capture2e)
        .with({ 'VAGRANT_CWD' => '/' }, 'vagrant', 'ssh-config', 'machine1')
        .and_return(['', double('status', success?: true)])

      subject.initialize_socket_if_needed(true)
    end
  end
end
