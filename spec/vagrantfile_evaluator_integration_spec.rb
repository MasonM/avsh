require 'spec_helper'

describe 'VagrantfileEvaluator integration tests' do
  subject do
    Avsh::VagrantfileEvaluator.new(double(debug: nil),
                                   Avsh::VagrantfileEnvironment.clone)
  end

  def vagrantfile(name)
    File.dirname(__FILE__) + "/vagrantfiles/#{name}"
  end

  context 'with Vagrant\'s Vagrantfile' do
    let!(:parsed_config) { subject.evaluate(vagrantfile('vagrant')) }

    it 'has a single unnamed machine' do
      expect(parsed_config.first_machine).to eq 'default'
    end

    it 'only has the default synced folder' do
      expect(parsed_config.collect_folders_by_machine).to eq(
        'default' => { '.' => '/vagrant' }
      )
    end
  end

  context 'with History of Science Society\'s Vagrantfile' do
    let!(:parsed_config) do
      subject.evaluate(vagrantfile('history_of_science_society'))
    end

    it 'has a single machine named "hss"' do
      expect(parsed_config.first_machine).to eq 'hss'
      expect(parsed_config.machine?('hss')).to be true
    end

    it 'has the default synced folder and one defined synced folder' do
      expect(parsed_config.collect_folders_by_machine).to eq(
        'hss' => {
          '.' => '/vagrant',
          File.dirname(__FILE__) => '/home/vagrant/hss'
        }
      )
    end
  end

  context 'with Vagrant Google Compute Engine\'s Vagrantfile' do
    let!(:parsed_config) { subject.evaluate(vagrantfile('vagrant_google')) }

    it 'has two machines, z1c and z1f' do
      expect(parsed_config.first_machine).to eq 'z1c'
      expect(parsed_config.machine?('z1c')).to be true
      expect(parsed_config.machine?('z1f')).to be true
    end

    it 'has the default synced folder for both machines' do
      expect(parsed_config.collect_folders_by_machine).to eq(
        'z1c' => { '.' => '/vagrant' },
        'z1f' => { '.' => '/vagrant' }
      )
    end
  end
end
