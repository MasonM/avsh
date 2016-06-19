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

    it 'returns FakeVMConfig object after init_fake_vm_config() is called' do
      vm_config = subject.init_fake_vm_config('/foo')
      expect(subject.vm).to eq vm_config
    end

    it 'returns DummyConfig when irrelevant method is called' do
      expect(subject.foobar).to eq described_class::DummyConfig
    end
  end

  context 'FakeVMConfig class' do
    let(:stubbed_parsed_config) do
      Struct.new(:vagrantfile_path, :default_synced_folders,
                 :machine_synced_folders, :primary_machine)
    end

    subject { described_class::FakeVMConfig.new('/foo') }

    it 'returns DummyConfig when irrelevant method is called' do
      expect(subject.foobar).to eq described_class::DummyConfig
    end

    context 'with a simple Vagrantfile' do
      it 'returns a correct ParsedConfig object' do
        expect(subject.parsed_config(stubbed_parsed_config))
          .to eq stubbed_parsed_config.new('/foo', {}, {}, nil)
      end
    end

    context 'with a multi-machine Vagrantfile' do
      before do
        subject.vm.synced_folder('/foo', '/bar')
        subject.define('machine1') {}
        subject.define('machine2', primary: true) do |c|
          c.vm.network :private_network, ip: '192.168.3.3'
          c.synced_folder('/foo', '/bar', disabled: true)
          c.synced_folder('/foo', '/bar2')
          c.synced_folder('/bar', '/baz')
        end
        subject.define('machine3') { |c| c.synced_folder('/1', '/2') }
      end

      it 'returns a correct ParsedConfig object' do
        expect(subject.parsed_config(stubbed_parsed_config))
          .to eq stubbed_parsed_config.new(
            '/foo',
            { '/bar' => { host_path: '/foo', disabled: nil } },
            {
              'machine1' => {},
              'machine2' => {
                '/bar' => { host_path: '/foo', disabled: true },
                '/bar2' => { host_path: '/foo', disabled: nil },
                '/baz' => { host_path: '/bar', disabled: nil }
              },
              'machine3' => { '/2' => { host_path: '/1', disabled: nil } }
            },
            'machine2'
          )
      end
    end

    context 'Loader class' do
      subject { described_class::Loader.new(double(debug: nil)) }

      let(:stub_vm_config) { double(parsed_config: 'success') }

      before do
        allow(described_class::FakeVagrantConfig)
          .to receive(:init_fake_vm_config)
          .with('/foo')
          .and_return(stub_vm_config)
      end

      context 'with valid vagrantfile' do
        it 'successfully returns parsed config' do
          expect(Kernel).to receive(:load).with('/foo')

          expect(subject.load_vagrantfile('/foo')).to eq 'success'
        end
      end

      context 'with non-existent vagrantfile' do
        it 'raises an exception' do
          allow(Kernel).to receive(:load).and_raise(Errno::ENOENT)

          expect { subject.load_vagrantfile('/foo') }
            .to raise_error(Avsh::VagrantfileEvalError)
        end
      end

      context 'with invalid vagrantfile' do
        it 'raises an exception' do
          allow(Kernel).to receive(:load).and_raise(SyntaxError)

          expect { subject.load_vagrantfile('/foo') }
            .to raise_error(Avsh::VagrantfileEvalError)
        end
      end
    end
  end
end
