require 'spec_helper'

describe Avsh::ArgumentParser do
  context 'with empty argv' do
    it 'returns defaults' do
      expect(subject.parse([])).to \
        eq([{ machine: nil, debug: false, reconnect: false, ssh_args: [] }, []])
    end
  end

  context 'with --help' do
    it 'displays help and exits' do
      expect { subject.parse(['-help']) }.to \
        output(/^Usage: avsh/).to_stdout.and raise_error(SystemExit)
    end
  end

  context 'with --version' do
    it 'displays version and exits' do
      expect { subject.parse(['--version']) }.to \
        output(/^avsh v#{Avsh::VERSION}/).to_stdout.and raise_error(SystemExit)
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
    it 'sets options[:ssh_args] properly' do
      expect(subject.parse(['--', '-T', '-6'])).to include(
        a_collection_including(ssh_args: ['-T', '-6'])
      )
    end
  end
end
