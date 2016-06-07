require 'spec_helper'

describe Avsh::Logger do
  context "debug mode enabled" do
    logger = Avsh::Logger.new(true)
    it "should output to STDOUT" do
      expect { logger.debug('FOO') }.to output(/#{__FILE__}.*FOO$/).to_stdout
    end
  end

  context "debug mode disabled" do
    logger = Avsh::Logger.new(false)
    it "should not output anything" do
      expect { logger.debug('FOO') }.to_not output.to_stdout
    end
  end
end
