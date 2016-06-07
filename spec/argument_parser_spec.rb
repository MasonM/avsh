require 'spec_helper'

describe Avsh::ArgumentParser do
  context 'with no options' do
    subject { Avsh::ArgumentParser.parse([]) }
    it 'returns defaults' do
      is_expected.to eq [{ machine: nil, debug: false, reconnect: false }, []]
    end
  end

  context 'with help' do
    subject { Avsh::ArgumentParser.parse(['--help']) }
    it 'displays help and exits' do
      is_expected.to eq [{ machine: nil, debug: false, reconnect: false }, []]
    end
  end
end
