require 'spec_helper'

describe Avsh::MachineGuestDirMatcher do
  let(:stub_config) { double(Avsh::ParsedConfig) }

  subject do
    described_class.new(double(debug: nil), '/foo/Vagrantfile', stub_config)
  end

  context 'with non-existent desired machine' do
    it 'raises exception' do
      allow(stub_config).to receive(:collect_folders_by_machine)
      allow(stub_config).to receive(:machine?).with('foo').and_return(false)
      expect { subject.match('/', 'foo') }
        .to raise_error(Avsh::MachineNotFoundError)
    end
  end

  context 'with desired machine' do
    context 'without synced folders' do
      it 'uses the desired machine' do
        allow(stub_config).to receive_messages(
          collect_folders_by_machine: {},
          machine?: true
        )
        expect(subject.match('/', 'machine1')).to eq ['machine1', nil]
      end
    end

    context 'no matching synced folders' do
      it 'uses the desired machine' do
        allow(stub_config).to receive_messages(
          collect_folders_by_machine: { machine1: { '/foo' => '/bar' } },
          machine?: true
        )
        expect(subject.match('/', 'machine1')).to eq ['machine1', nil]
      end
    end

    context 'multiple inexact matching synced folders' do
      it 'uses the desired machine and first matching guest dir' do
        allow(stub_config).to receive_messages(
          collect_folders_by_machine: {
            'machine1' => { '/foo' => '/bar' },
            'machine2' => { '/bam' => '/baz', '/foo' => '/bar2' },
            'machine3' => {}
          },
          machine?: true
        )
        expect(subject.match('/foo/foo2/', 'machine2'))
          .to eq ['machine2', '/bar2/foo2']
      end
    end
  end

  context 'without desired machine' do
    context 'without synced folders' do
      it 'uses the primary machine if it exists' do
        allow(stub_config).to receive_messages(
          collect_folders_by_machine: {},
          primary_machine: 'machine1'
        )
        expect(subject.match('/')).to eq ['machine1', nil]
      end

      it 'uses the first machine if no primary machine exists' do
        allow(stub_config).to receive_messages(
          collect_folders_by_machine: {},
          primary_machine: nil,
          first_machine: 'machine2'
        )
        expect(subject.match('/')).to eq ['machine2', nil]
      end
    end
  end

  context 'exact match for a synced folder' do
    it 'uses the guest dir' do
      allow(stub_config).to receive_messages(
        collect_folders_by_machine: { 'machine1' => { '/bam' => '/baz' } }
      )
      expect(subject.match('/bam/')).to eq ['machine1', '/baz/']
    end
  end

  context 'multiple inexact matching synced folders' do
    it 'uses the first matching machine and guest dir' do
      allow(stub_config).to receive_messages(
        collect_folders_by_machine: {
          'machine1' => { '/bam' => '/baz' },
          'machine2' => { '/baz' => '/baz2', '/foo' => '/bar2' },
          'machine3' => { '/foo' => '/bar' }
        }
      )
      expect(subject.match('/foo/foo2/')).to eq ['machine2', '/bar2/foo2']
    end
  end
end
