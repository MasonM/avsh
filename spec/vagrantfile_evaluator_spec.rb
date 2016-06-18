require 'spec_helper'

describe Avsh::VagrantfileEvaluator do
  include FakeFS::SpecHelpers

  let(:environment) { class_double(Avsh::VagrantfileEnvironment) }

  subject { described_class.new(double(debug: nil), environment) }

  before { allow(environment).to receive(:prep) }

  context 'with valid vagrantfile' do
    before { File.write('/Vagrantfile', 'foo') }

    it 'successfully returns parsed config' do
      allow(environment).to receive(:parsed_config).and_return('success')
      expect(environment).to receive(:module_eval).with('foo', '/Vagrantfile')

      expect(subject.evaluate('/Vagrantfile')).to eq 'success'
    end
  end

  context 'with non-existent vagrantfile' do
    it 'raises an exception' do
      expect { subject.evaluate('/foo') }
        .to raise_error(Avsh::VagrantfileEvalError)
    end
  end

  context 'with invalid vagrantfile' do
    before { File.write('/Vagrantfile', 'foo') }

    it 'raises an exception' do
      allow(environment).to receive(:module_eval).and_raise(SyntaxError.new)

      expect { subject.evaluate('/foo') }
        .to raise_error(Avsh::VagrantfileEvalError)
    end
  end
end
