require 'spec_helper'

shared_examples_for 'a normal command' do |execute_args, ssh_cmd_args|
  it 'executes succesfully' do
    expect(Kernel).to receive(:exec).with('ssh', '-o ControlPath /s.sock',
                                          *ssh_cmd_args)
    expect { subject.execute(*execute_args) }.to raise_error(Avsh::ExecSshError)
  end
end

describe Avsh::SshCommandExecutor do
  subject { described_class.new(double(debug: nil), 'foo_machine', '/s.sock') }

  context 'with non-empty command and a guest dir' do
    it_behaves_like 'a normal command', ['ls', '/somedir'],
                    ['-t', 'foo_machine', 'cd /somedir; ls']
  end

  context 'with empty command and a guest dir' do
    it_behaves_like 'a normal command', ['', '/somedir'],
                    ['-t', 'foo_machine', 'cd /somedir; exec $SHELL -l']
  end

  context 'with non-empty command and no guest dir' do
    it_behaves_like 'a normal command', ['pwd'],
                    ['-t', 'foo_machine', 'pwd']
  end

  context 'with user SSH args, non-empty command and no guest dir' do
    it_behaves_like 'a normal command', ['pwd', nil, '-T -6'],
                    ['-T', '-6', 'foo_machine', 'pwd']
  end
end
