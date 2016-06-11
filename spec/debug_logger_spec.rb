require 'spec_helper'

describe Avsh::DebugLogger do
  context 'debug mode enable' do
    subject { described_class.new(true) }
    it 'should output to STDOUT' do
      expect { subject.debug('FOO') }.to output(/#{__FILE__}.*FOO$/).to_stdout
    end
  end

  context 'debug mode disabled' do
    subject { described_class.new(false) }
    it 'should not output anything' do
      expect { subject.debug('FOO') }.to_not output.to_stdout
    end
  end
end
