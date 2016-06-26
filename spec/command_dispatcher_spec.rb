require 'spec_helper'

describe Avsh::CommandDispatcher do
  let(:stub_multiplex_manager) { double(Avsh::SshMultiplexManager) }
  let(:stub_matcher) { double(Avsh::MachineGuestDirMatcher) }
  let(:stub_executor) { double(Avsh::SshCommandExecutor) }
  let(:stub_logger) { double(debug: nil) }
  let(:options) { { machine: 'bar', reconnect: true, ssh_options: '-6' } }

  subject do
    described_class.new(stub_logger, stub_multiplex_manager, stub_matcher)
  end

  context 'dispatch with single matched machine' do
    it 'executes command' do
      allow(stub_matcher)
        .to receive(:match).with('/foo', options[:machine])
        .and_return('machine1' => '/etc')

      expect(Avsh::SshCommandExecutor)
        .to receive(:new).with(anything, 'machine1', anything)
        .and_return(stub_executor)

      expect(stub_executor).to receive(:connect).with(options[:reconnect])
      expect(stub_executor)
        .to receive(:execute).with('ls', '/etc', true, options[:ssh_options])

      subject.dispatch('/foo', 'ls', options)
    end
  end

  context 'dispatch with multiple matched machines' do
    it 'raises an error if command is empty' do
      allow(stub_matcher).to receive(:match)
        .and_return('machine1' => nil, 'machine2' => nil)

      expect { subject.dispatch('', '', options) }
        .to raise_error(Avsh::NoCommandWithMultipleMachinesError)
    end

    it 'executes command on each machine' do
      allow(stub_matcher)
        .to receive(:match).with('/foo', options[:machine])
        .and_return('machine1' => nil, 'machine2' => nil)

      expect(Avsh::SshCommandExecutor)
        .to receive(:new).twice.and_return(stub_executor)

      expect(stub_executor).to receive(:connect).twice.with(options[:reconnect])
      expect(stub_executor).to receive(:execute).twice
        .with('ls', nil, false, options[:ssh_options])

      subject.dispatch('/foo', 'ls', options)
    end
  end
end
