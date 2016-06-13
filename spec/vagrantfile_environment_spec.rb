require 'spec_helper'

describe Avsh::VagrantfileEnvironment do
  context 'prepping Vagrant module' do
    it 'correctly sets dummy Configure object' do
      dummy_configure = described_class.prep_vagrant_configure
      expect(described_class::Vagrant.class_variable_get(:@@configure))
        .to eq dummy_configure
    end
  end

  context 'dummy Vagrant module' do
    subject { described_class::Vagrant }

    it 'returns true when has_plugin? is called' do
      expect(subject.has_plugin?('foo')).to eq true
    end

    it 'yields the set Configure object when configure() is called' do
      subject.class_variable_set(:@@configure, 'foo')
      expect { |b| subject.configure(&b) }.to yield_with_args('foo')
    end

    it 'ignores other methods' do
      expect(subject.foobar).to eq nil
    end
  end

  context 'dummy Configure module' do
    stubbed_parsed_config = Struct.new(:default_synced_folders,
                                       :machine_synced_folders,
                                       :primary_machine)

    subject { described_class::Configure.new }

    context 'with simple Vagrantfile' do
      it 'returns a correct ParsedConfig object' do
        expect(subject.parsed_config(stubbed_parsed_config))
          .to eq stubbed_parsed_config.new({}, {}, nil)
      end
    end

    context 'with multi-machine Vagrantfile' do
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
            { '/foo' => '/bar' },
            {
              'machine1' => {},
              'machine2' => { '/foo' => '/bar2', '/bar' => '/baz' },
              'machine3' => { '/1' => '/2' }
            },
            'machine2'
          )
      end
    end
  end
end
