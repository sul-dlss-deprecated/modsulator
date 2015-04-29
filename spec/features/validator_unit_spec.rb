require 'equivalent-xml'
require "modsulator/validator"

describe Validator do
  describe "initialize" do
    it "validates a valid XML file using the internal XML Schema Definition file" do

      # Nokogiri won't load the imported schema unless we explicitly set the current dir. This only seems to be a problem from within RSpec, though.
      Dir.chdir(File.expand_path("lib/modsulator/")) do
        validator = Validator.new("modsulator.xsd")
        error_list = validator.validate_xml_string(File.read(File.join(FIXTURES_DIR, 'crowdsourcing_bridget_1.xml')))
        expect(error_list).to be_empty()
      end
    end

    it "lists errors for an invalid XML file using the internal XML Schema Definition file" do
      Dir.chdir(File.expand_path("lib/modsulator/")) do
        validator = Validator.new("modsulator.xsd")
        error_list = validator.validate_xml_string(File.read(File.join(FIXTURES_DIR, 'invalid_crowdsourcing_bridget_1.xml')))
        expect(error_list.length()).to eq(3)
      end
    end

    it "validates a valid XML file by automatically picking up the internal XML Schema Definition file" do

      # Nokogiri won't load the imported schema unless we explicitly set the current dir. This only seems to be a problem from within RSpec, though.
      Dir.chdir(File.expand_path("lib/modsulator/")) do
        validator = Validator.new()
        error_list = validator.validate_xml_string(File.read(File.join(FIXTURES_DIR, 'crowdsourcing_bridget_1.xml')))
        expect(error_list).to be_empty()
      end
    end

    it "lists errors for an invalid XML file when automatically picking up the internal XML Schema Definition file" do
      Dir.chdir(File.expand_path("lib/modsulator/")) do
        validator = Validator.new("modsulator.xsd")
        error_list = validator.validate_xml_string(File.read(File.join(FIXTURES_DIR, 'invalid_crowdsourcing_bridget_1.xml')))
        expect(error_list.length()).to eq(3)
      end
    end
    
  end
end
