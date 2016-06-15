require 'spec_helper'

describe Avsh::VagrantfileEvaluator do
  include FakeFS::SpecHelpers

  let(:environment) { class_double(Avsh::VagrantfileEnvironment) }

  subject { described_class.new(double(debug: nil), environment) }

  context 'with valid vagrantfile' do
    before { File.write('/Vagrantfile', 'foo') }

    it 'successfully returns parsed config' do
      dummy_configure = double
      allow(dummy_configure).to receive(:parsed_config).and_return('success')
      allow(environment).to receive(:prep_vagrant_configure)
        .and_return(dummy_configure)

      expect(environment).to receive(:module_eval).with('foo', '/Vagrantfile')

      expect(subject.evaluate('/Vagrantfile')).to eq 'success'
    end
  end

  context 'with non-existent vagrantfile' do
    it 'raises an exception' do
      allow(environment).to receive(:prep_vagrant_configure)

      expect { subject.evaluate('/foo') }
        .to raise_error(Avsh::VagrantfileEvalError)
    end
  end

  context 'with invalid vagrantfile' do
    before { File.write('/Vagrantfile', 'foo') }

    it 'raises an exception' do
      allow(environment).to receive(:prep_vagrant_configure)
      allow(environment).to receive(:module_eval).and_raise(SyntaxError.new)

      expect { subject.evaluate('/foo') }
        .to raise_error(Avsh::VagrantfileEvalError)
    end
  end
end
