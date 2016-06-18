require 'spec_helper'

describe Avsh::VagrantfileEnvironment do
  context 'fake Vagrant module' do
    subject { described_class::Vagrant }

    it 'returns true when has_plugin? is called' do
      expect(subject.has_plugin?('foo')).to eq true
    end

    it 'yields FakeVagrantConfig when configure() is called' do
      expect { |b| subject.configure(&b) }
        .to yield_with_args(described_class::FakeVagrantConfig)
    end

    it 'ignores irrelevant methods' do
      expect(subject.foobar).to eq nil
    end
  end

  context 'FakeVagrantConfig module' do
    subject { described_class::FakeVagrantConfig }

    it 'returns the same FakeVMConfig object when vm is called twice' do
      expect(subject.vm).to eq subject.vm
    end

    it 'returns DummyConfig when irrelevant method is called' do
      expect(subject.foobar).to eq described_class::DummyConfig
    end
  end

  context 'FakeVMConfig class' do
    let(:stubbed_parsed_config) do
      Struct.new(:default_synced_folders, :machine_synced_folders,
                 :primary_machine)
    end

    subject { described_class::FakeVMConfig.new }

    it 'returns DummyConfig when irrelevant method is called' do
      expect(subject.foobar).to eq described_class::DummyConfig
    end

    context 'with a simple Vagrantfile' do
      it 'returns a correct ParsedConfig object' do
        expect(subject.parsed_config(stubbed_parsed_config))
          .to eq stubbed_parsed_config.new({ '.' => '/vagrant' }, {}, nil)
      end
    end

    context 'with a multi-machine Vagrantfile' do
      before do
        subject.synced_folder('/foo', '/bar')
        subject.define('machine1') {}
        subject.define('machine2', primary: true) do |c|
          c.vm.network :private_network, ip: '192.168.3.3'
          c.synced_folder('/foo', '/bar2')
          c.synced_folder('/bar', '/baz')
        end
        subject.define('machine3') { |c| c.synced_folder('/1', '/2') }
      end

      it 'returns a correct ParsedConfig object' do
        expect(subject.parsed_config(stubbed_parsed_config))
          .to eq stubbed_parsed_config.new(
            { '.' => '/vagrant', '/foo' => '/bar' },
            {
              'machine1' => { '.' => '/vagrant' },
              'machine2' => { '.' => '/vagrant', '/foo' => '/bar2',
                              '/bar' => '/baz' },
              'machine3' => { '.' => '/vagrant', '/1' => '/2' }
            },
            'machine2'
          )
      end
    end
  end
end
