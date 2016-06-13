require 'spec_helper'

shared_examples 'displays output and exits' do |args, expected_output|
  it do
    expect { subject.parse(args) }.to output(expected_output).to_stdout
      .and raise_error(SystemExit)
  end
end

shared_examples 'raises exception' do |args, exception|
  it { expect { subject.parse(args) }.to raise_error(exception) }
end

shared_examples 'sets option when arg supplied' do |args, option_hash|
  it do
    expect(subject.parse(args)).to include(a_collection_including(option_hash))
  end
end

describe Avsh::ArgumentParser do
  context 'with empty argv' do
    it 'returns defaults' do
      default_opts = {
        machine: nil,
        debug: false,
        reconnect: false,
        ssh_args: '',
        command: nil
      }
      expect(subject.parse(['ls'])).to eq([default_opts, 'ls'])
    end
  end

  context 'with invalid option' do
    it_behaves_like 'displays output and exits', ['--foobar'], /^Usage: avsh/
  end

  context 'with --help' do
    it_behaves_like 'displays output and exits', ['--help'], /^Usage: avsh/
  end

  context 'with --version' do
    it_behaves_like 'displays output and exits', ['--version'],
                    /^avsh v#{Avsh::VERSION}/
  end

  context 'with reconnect' do
    ['-r', '--reconnect'].each do |opt|
      it_behaves_like 'sets option when arg supplied', [opt], reconnect: true
    end
  end

  context 'with debug' do
    ['-d', '--debug'].each do |opt|
      it_behaves_like 'sets option when arg supplied', [opt], debug: true
    end
  end

  context 'with machine' do
    [['-m', 'foo'], ['--machine=foo']].each do |opt|
      it_behaves_like 'sets option when arg supplied', opt, machine: 'foo'
    end
  end

  context 'with custom ssh args' do
    [['-s', '-6 -T'], ['--ssh-args=-6 -T']].each do |opt|
      it_behaves_like 'sets option when arg supplied', opt, ssh_args: '-6 -T'
    end
  end

  context 'with command via -c option' do
    context 'with machine as an option' do
      it_behaves_like 'raises exception', ['-c', 'foo', '-m', 'machine1'],
                      Avsh::VagrantCompatibilityModeMachineError
    end

    context 'with single machine machine in place of normal command' do
      it 'returns right command and machine' do
        opts = {
          machine: 'machine1',
          debug: false,
          reconnect: false,
          ssh_args: '',
          command: 'ls'
        }
        expect(subject.parse(['-c', 'ls', 'machine1'])).to eq([opts, 'ls'])
      end
    end

    context 'with multiple machines in place of normal command' do
      it_behaves_like 'raises exception', ['-c', 'foo', 'machine1', 'machine2'],
                      Avsh::MultipleMachinesError
    end
  end
end
