require 'spec_helper'

describe Avsh::ParsedConfig do
  context 'with /vagrant mapped to a non-default directory' do
    subject { described_class.new({ '.' => '/foo/bar/' }, {}, nil) }

    it 'returns the mapped directory in collect_folders_by_machine' do
      expect(subject.collect_folders_by_machine).to eq(
        'default' => { '.' => '/foo/bar/' }
      )
    end
  end

  context 'with single machine' do
    subject { described_class.new({}, {}, nil) }

    it 'returns false in machine?' do
      expect(subject.machine?('foo')).to be false
    end

    it 'returns \'default\' in first_machine' do
      expect(subject.first_machine).to eq 'default'
    end

    it 'returns nil in primary_machine' do
      expect(subject.primary_machine).to be nil
    end

    it 'returns default with /vagrant mapping in collect_folders_by_machine' do
      expect(subject.collect_folders_by_machine).to eq(
        'default' => { '.' => '/vagrant' }
      )
    end
  end

  context 'with multiple machines' do
    subject do
      described_class.new(
        { '/default' => '/foo/' },
        {
          'first' => double(synced_folders: { '/foo' => '/bar' }),
          'primary' => double(synced_folders: {}),
          'overrides_defaults' => double(
            synced_folders: { '/foo' => '/vagrant', '/default' => '/new' }
          )
        },
        'primary'
      )
    end

    it 'returns false in machine? when given non-existent machine' do
      expect(subject.machine?('foo')).to be false
    end

    it 'returns true in machine? when given valid machine' do
      expect(subject.machine?('overrides_defaults')).to be true
    end

    it 'returns name of first machine in first_machine' do
      expect(subject.first_machine).to eq 'first'
    end

    it 'returns name of primary machine in primary_machien' do
      expect(subject.primary_machine).to eq 'primary'
    end

    it 'returns synced folder mappings in collect_folders_by_machine' do
      expect(subject.collect_folders_by_machine).to eq(
        'first' => {
          '/default' => '/foo/',
          '.' => '/vagrant',
          '/foo' => '/bar'
        },
        'primary' => {
          '/default' => '/foo/',
          '.' => '/vagrant'
        },
        'overrides_defaults' => {
          '/default' => '/new',
          '/foo' => '/vagrant'
        }
      )
    end
  end
end
