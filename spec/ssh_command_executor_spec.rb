require 'spec_helper'

shared_examples_for 'a normal command' do |execute_args, ssh_cmd_args, command|
  it 'executes succesfully' do
    allow(stub_multiplex_manager).to receive(:controlpath_option)
      .with(machine_name).and_return '-o ControlPath foo'

    expect(Kernel).to receive(:exec).with('ssh', '-o ControlPath foo',
                                          *ssh_cmd_args, machine_name, command)

    expect { subject.execute(*execute_args) }.to raise_error(Avsh::ExecSshError)
  end
end

describe Avsh::SshCommandExecutor do
  let(:machine_name) { 'foo_machine' }
  let(:stub_multiplex_manager) { double(Avsh::SshMultiplexManager) }

  subject do
    described_class.new(double(debug: nil), machine_name,
                        stub_multiplex_manager)
  end

  context 'connect' do
    let(:stub_active?) do
      allow(stub_multiplex_manager).to receive(:active?).with(machine_name)
    end

    it 'closes socket if it\'s active and reconnect is true' do
      stub_active?.and_return(true)

      expect(stub_multiplex_manager)
        .to receive(:close_socket).with(machine_name)

      subject.connect(true)
    end

    it 'does not close if reconnect is true and socket is not active' do
      stub_active?.and_return(false, true)

      subject.connect(true)
    end

    it 'initializes socket if socket is not active' do
      stub_active?.and_return(false)

      expect(stub_multiplex_manager)
        .to receive(:initialize_socket).with(machine_name)

      subject.connect
    end

    it 'does not intialize socket if socket is active' do
      stub_active?.and_return(true)
      subject.connect
    end
  end

  context 'execute' do
    context 'with non-empty command and a guest dir' do
      it_behaves_like 'a normal command', ['ls', '/somedir'], ['-t'],
                      'cd /somedir; ls'
    end

    context 'with empty command and a guest dir' do
      it_behaves_like 'a normal command', ['', '/somedir'], ['-t'],
                      'cd /somedir; exec $SHELL -l'
    end

    context 'with non-empty command and no guest dir' do
      it_behaves_like 'a normal command', ['pwd'], ['-t'], 'pwd'
    end

    context 'with user SSH args, non-empty command and no guest dir' do
      it_behaves_like 'a normal command', ['pwd', nil, '-T -6'],
                      ['-T', '-6'], 'pwd'
    end
  end
end
