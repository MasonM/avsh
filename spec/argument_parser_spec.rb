require 'spec_helper'

describe Avsh::ArgumentParser do
  context 'with empty argv' do
    it 'returns defaults' do
      expect(described_class.parse([])).to eq({
        options: { machine: nil, debug: false, reconnect: false },
        command: []
      })
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

  context 'with reconnect' do
    [ '-r', '--reconnect'].each do |opt|
      it "sets reconnect when #{opt} supplied" do
        expect(described_class.parse([opt])).to include(
          :options => a_collection_including(reconnect: true)
        )
      end
    end
  end

  context 'with debug' do
    [ '-d', '--debug'].each do |opt|
      it "sets debug when #{opt} supplied" do
        expect(described_class.parse([opt])).to include(
          :options => a_collection_including(debug: true)
        )
      end
    end
  end

  context 'with machine' do
    [ '-m foo', '--machine=foo'].each do |opt|
      it "sets machine to 'foo' when #{opt} supplied" do
        expect(described_class.parse([opt])).to include(
          :options => a_collection_including(machine: 'foo')
        )
      end
    end
  end
end
