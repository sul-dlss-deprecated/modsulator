require 'modsulator/normalizer'

describe Normalizer do
  before :all do
    # Create common variables shared across tests
    @fixtures_dir = File.expand_path("../../fixtures", __FILE__)
    @normalizer = Normalizer.new
  end
  
  describe "basic functionality" do
    it "formats text blocks correctly" do
      bad_string = "       This is		some text		with more


than 		one


problem

	inside

"
      expect(@normalizer.clean_text(bad_string)).to eq("This is some text with more than one problem inside")
    end
  end
end
