require 'spec_helper'


shared_examples "finds Vagrantfile" do |host_directory, vagrantfile_path|
    before do
      FileUtils.mkdir_p(host_directory)
      FileUtils.mkdir_p(File.dirname(vagrantfile_path))
      FileUtils.touch(vagrantfile_path)
    end

    it 'returns path' do
      expect(subject.find(host_directory)).to eq vagrantfile_path
    end
end

describe Avsh::VagrantfileFinder do
  include FakeFS::SpecHelpers

  context 'no Vagrantfile' do
    it 'raises an exception' do
      expect { subject.find('/') }.to \
        raise_error(Avsh::VagrantfileNotFoundError)
    end
  end

  context 'without vagrant_cwd or vagrantfile_name' do
    context 'in same directory as a Vagrantfile' do
      include_examples "finds Vagrantfile", '/', '/Vagrantfile'
    end

    context 'in same directory as a vagrantfile (lower-case)' do
      include_examples "finds Vagrantfile", '/', '/vagrantfile'
    end

    context 'in sub-sub directory of a Vagrantfile' do
      include_examples "finds Vagrantfile", '/foo/bar/baz', '/foo/Vagrantfile'
    end
  end

  context 'with vagrant_cwd' do
    subject { described_class.new('/foo') }

    context 'in the vagrant_cwd directory with a Vagrantfile' do
      include_examples "finds Vagrantfile", '/foo/bar/baz', '/foo/Vagrantfile'
    end

    context 'in some other directory with a Vagrantfile in vagrant_cwd' do
      include_examples "finds Vagrantfile", '/bam', '/foo/Vagrantfile'
    end

    context 'in directory different than vagrant_cwd with a Vagrantfile' do
      before do
        FileUtils.mkdir_p('/foo/bar')
        FileUtils.touch('/foo/bar/Vagrantfile')
      end

      it 'raises an exception' do
        expect { subject.find('/foo/bar') }.to \
          raise_error(Avsh::VagrantfileNotFoundError)
      end
    end
  end

  context 'with vagrantfile_name' do
    subject { described_class.new(nil, 'foofile') }

    context 'in same directory with vagrantfile_name' do
      include_examples "finds Vagrantfile", '/', '/foofile'
    end

    context 'in sub directory with vagrantfile_name' do
      include_examples "finds Vagrantfile", '/foo/foofile', '/foo/foofile'
    end

    context 'in directory with a Vagrantfile not matching vagrantfile_name' do
      before { FileUtils.touch('/Vagrantfile') }

      it 'raises an exception' do
        expect { subject.find('/') }.to \
          raise_error(Avsh::VagrantfileNotFoundError)
      end
    end
  end
end
