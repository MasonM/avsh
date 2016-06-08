require 'spec_helper'

describe Avsh::ArgumentParser do
  context 'with no options' do
    subject { described_class.parse([]) }
    it 'returns defaults' do
      is_expected.to eq [{ machine: nil, debug: false, reconnect: false }, []]
    end
  end

  context 'with --help' do
    subject { described_class.parse(['--help']) }
    it 'displays help and exits' do
      expect { subject }.to output(/^Usage: avsh/).to_stdout.and \
        raise_error(SystemExit)
    end
  end

  context 'with --version' do
    subject { described_class.parse(['--version']) }
    it 'displays version and exits' do
      expect { subject }.to output(/^avsh v#{Avsh::VERSION}/).to_stdout.and \
        raise_error(SystemExit)
    end
  end

  context 'with boolean options' do
    subject { described_class.parse(['-r --debug']) }
    it 'sets options hash properly' do
      is_expected.to eq [{ machine: nil, debug: true, reconnect: true }, []]
    end
  end

  context 'with --machine' do
    subject { described_class.parse(['-m foo']) }
    it 'sets :machine in options hash' do
      is_expected.to eq [{ machine: 'foo', debug: false, reconnect: false }, []]
    end
  end
end
