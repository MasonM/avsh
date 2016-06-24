require 'spec_helper'

describe Avsh::ParsedConfig do
  context 'with /vagrant mapped to a non-default directory' do
    subject do
      described_class.new('/v', { '/foo/bar' => { host_path: '/v' } }, {}, nil)
    end

    it 'returns the mapped directory in collect_folders_by_machine' do
      expect(subject.collect_folders_by_machine).to eq(
        'default' => { '/foo/bar' => '/v' }
      )
    end
  end

  context 'with single machine' do
    subject { described_class.new('/va', {}, {}, nil) }

    it 'raises exception in match_machines' do
      expect { subject.match_machines!('foo') }
        .to raise_error(Avsh::MachineNotFoundError)
    end

    it 'returns \'default\' in first_machine' do
      expect(subject.first_machine).to eq 'default'
    end

    it 'returns nil in primary_machine' do
      expect(subject.primary_machine).to be nil
    end

    it 'returns default vagrant share in collect_folders_by_machine' do
      expect(subject.collect_folders_by_machine).to eq(
        'default' => { '/vagrant' => '/va' }
      )
    end
  end

  context 'with disabled folders' do
    subject do
      described_class.new(
        '/vagrantfile_path',
        { '/foo/' => { host_path: '/default' } },
        {
          'main' => {
            '/foo/' => { host_path: '/default', disabled: true },
            '/vagrant' => { host_path: '/vagrantfile_path', disabled: true },
            '/bar/' => { host_path: '/baz' }
          }
        },
        nil
      )
    end

    it 'only returns the /bar/ => /baz/ folder in collect_folders_by_machine' do
      expect(subject.collect_folders_by_machine).to eq(
        'main' => { '/bar/' => '/baz' }
      )
    end
  end

  context 'with multiple machines' do
    subject do
      described_class.new(
        '/vagrantfile_path',
        { '/foo/' => { host_path: '/default' } },
        {
          'first' => { '/bar' => { host_path: '/foo' } },
          'primary' => {},
          'overrides_defaults' => {
            '/vagrant2' => { host_path: '/vagrantfile_path' },
            '/foo/' => { host_path: '/new' }
          }
        },
        'primary'
      )
    end

    context 'match_machines!' do
      it 'raises exception with a non-existent machine' do
        expect { subject.match_machines!('foo') }
          .to raise_error(Avsh::MachineNotFoundError)
      end

      it 'returns array with the machine given a valid machine as a string' do
        expect(subject.match_machines!('overrides_defaults'))
          .to eq ['overrides_defaults']
      end

      it 'returns array of machines given a valid comma-separated list' do
        expect(subject.match_machines!('primary, overrides_defaults, first'))
          .to eq %w(primary overrides_defaults first)
      end

      it 'raises exception given comma-separated list with invalid machine' do
        expect { subject.match_machines!('primary, foo') }
          .to raise_error(Avsh::MachineNotFoundError)
      end

      it 'returns array of machines given valid regular expression' do
        expect(subject.match_machines!('/prim.*y/')).to eq ['primary']
        expect(subject.match_machines!('/first|override/'))
          .to eq %w(first overrides_defaults)
      end

      it 'raises exception given invalid regexp' do
        expect { subject.match_machines!('/foo(/') }
          .to raise_error(Avsh::MachineRegexpError)
      end

      it 'raises exception given regexp that doesn\'t match anything' do
        expect { puts subject.match_machines!('/dlsfks/') }
          .to raise_error(Avsh::MachineNotFoundError)
      end
    end

    it 'returns name of first machine in first_machine' do
      expect(subject.first_machine).to eq 'first'
    end

    it 'returns name of primary machine in primary_machien' do
      expect(subject.primary_machine).to eq 'primary'
    end

    it 'returns synced folder mappings in collect_folders_by_machine' do
      # call to_a on the hash because we want to ensure 'primary' is ordered to
      # the top, and the normal hash comparisons don't respect order
      expect(subject.collect_folders_by_machine.to_a).to eq [
        ['primary', {
          '/foo/' => '/default',
          '/vagrant' => '/vagrantfile_path'
        }],
        ['first', {
          '/foo/' => '/default',
          '/vagrant' => '/vagrantfile_path',
          '/bar' => '/foo'
        }],
        ['overrides_defaults', {
          '/foo/' => '/new',
          '/vagrant2' => '/vagrantfile_path'
        }]
      ]
    end
  end
end
