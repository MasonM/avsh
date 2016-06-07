require 'spec_helper'

describe Avsh::ArgumentParser do
  context "with no options" do
    subject { Avsh::ArgumentParser.parse([]) }
    it { is_expected.to eq [{machine: nil, debug: false, reconnect: false}, []] }
  end
end
