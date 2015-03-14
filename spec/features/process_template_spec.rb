require "modsulator"
require "modsulator_helper.rb"

# before delete tmp files
# execute modsulator with test:002
# check that the file tmp/test:002 exists
# after delete tmp files


describe Modsulator do
  before :all do
    # Create common variables shared across tests and clear out temp directory
    @mods_generator = Modsulator.new
    @fixtures_dir = File.expand_path("../../fixtures", __FILE__)
    @tmp_dir = File.expand_path("../../tmp", __FILE__)
    Dir.foreach(@tmp_dir) {|f| fn = File.join(@tmp_dir, f); File.delete(fn) if f != '.' && f != '..' && !File.directory?(fn)}
  end
  
  describe "initialized" do
    it "loads sample template 002 correctly" do
      @mods_generator.generate_normalized_mods(File.join(@fixtures_dir, "SuperMods-01-template.xml"),
                                               File.join(@fixtures_dir, "test_002.xlsx"),
                                               @tmp_dir)
      
      expect(File).to be_readable(File.join(@tmp_dir, "test:002.xml"))
      
      expected_result = File.read(File.join(@fixtures_dir, "test:002.xml"))
      actual_result = File.read(File.join(@tmp_dir, "test:002.xml"))
      expect(actual_result).to eq(expected_result)
    end
  end

  after :all do
    Dir.foreach(@tmp_dir) {|f| File.delete(File.join(@tmp_dir, f)) if f != '.' && f != '..' && !File.directory?(f)}
  end
end
