require 'spec_helper'

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
    it 'displays help and exits' do
      expect { subject.parse(['-foobar']) }
        .to output(/^Usage: avsh/).to_stdout.and raise_error(SystemExit)
    end
  end

  context 'with --help' do
    it 'displays help and exits' do
      expect { subject.parse(['-help']) }
        .to output(/^Usage: avsh/).to_stdout.and raise_error(SystemExit)
    end
  end

  context 'with --version' do
    it 'displays version and exits' do
      expect { subject.parse(['--version']) }
        .to output(/^avsh v#{Avsh::VERSION}/)
        .to_stdout.and raise_error(SystemExit)
    end
  end

  context 'with reconnect' do
    ['-r', '--reconnect'].each do |opt|
      it "sets reconnect when #{opt} supplied" do
        expect(subject.parse([opt])).to include(
          a_collection_including(reconnect: true)
        )
      end
    end
  end

  context 'with debug' do
    ['-d', '--debug'].each do |opt|
      it "sets debug when #{opt} supplied" do
        expect(subject.parse([opt])).to include(
          a_collection_including(debug: true)
        )
      end
    end
  end

  context 'with machine' do
    [['-m', 'foo'], ['--machine=foo']].each do |opt|
      it "sets machine to 'foo' when #{opt} supplied" do
        expect(subject.parse(opt)).to include(
          a_collection_including(machine: 'foo')
        )
      end
    end
  end

  context 'with custom ssh args' do
    [['-s', '-6 -T'], ['--ssh-args=-6 -T']].each do |opt|
      it "sets options[:ssh_args] properly when #{opt} supplied" do
        expect(subject.parse(opt)).to include(
          a_collection_including(ssh_args: '-6 -T')
        )
      end
    end
  end

  context 'with command via -c option' do
    context 'with machine as an option' do
      it 'raises an exception' do
        expect { subject.parse(['-c', 'foo', '-m', 'machine1']) }
          .to raise_error(Avsh::VagrantCompatibilityModeMachineError)
      end
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
      it 'raises an exception' do
        expect { subject.parse(['-c', 'foo', 'machine1', 'machine2']) }
          .to raise_error(Avsh::MultipleMachinesError)
      end
    end
  end
end
