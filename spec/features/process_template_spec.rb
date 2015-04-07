require "modsulator"
require "modsulator_helper.rb"

describe Modsulator do
  before :all do
    # Create common variables shared across tests and clear out temp directory
    @tmp_dir      = File.expand_path("../../../tmp", __FILE__)
    Dir.mkdir(@tmp_dir) unless Dir.exists?(@tmp_dir)
    Dir.foreach(@tmp_dir) {|f| fn = File.join(@tmp_dir, f); File.delete(fn) if f != '.' && f != '..' && !File.directory?(fn)}
  end

  describe "initialized" do
    {
      'test_002.xlsx' => 'Excel Workbook',
      'test_002.csv'  => 'CSV'
    }.each do |testfile, description|
      it "loads sample template 002 in #{description} format correctly" do
        Modsulator.new(File.join(FIXTURES_DIR, testfile), file: File.join(FIXTURES_DIR, "modsulator_template.xml")).generate_normalized_mods(@tmp_dir)
        expect(File).to be_readable(File.join(@tmp_dir, "test:002.xml"))
        actual_result   = File.read(File.join(@tmp_dir, "test:002.xml"))
        expected_result = File.read(File.join(FIXTURES_DIR, "test:002.xml"))
        expect(actual_result).to eq(expected_result)
      end
    end
  end

  after :all do
    Dir.foreach(@tmp_dir) {|f| File.delete(File.join(@tmp_dir, f)) if f != '.' && f != '..' && !File.directory?(f)}
  end
end
