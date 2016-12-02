RSpec.describe Modsulator do
  before :all do
    # Create common variables shared across tests and clear out temp directory
    @tmp_dir      = File.expand_path("../../../tmp", __FILE__)
    Dir.mkdir(@tmp_dir) unless Dir.exists?(@tmp_dir)
    Dir.foreach(@tmp_dir) {|f| fn = File.join(@tmp_dir, f); File.delete(fn) if f != '.' && f != '..' && !File.directory?(fn)}
  end

  describe "initialized" do
    {
      'edition_physLoc_intmediatype.xlsx' => 'Excel Workbook',
    }.each do |testfile, description|
      it "loads sample test file in #{description} format correctly" do
        generated_xml_string = Modsulator.new(File.join(FIXTURES_DIR, testfile), testfile).convert_rows()
        generated_xml = Nokogiri::XML(generated_xml_string)
        expected_xml = Nokogiri::XML(File.read(File.join(FIXTURES_DIR, "edition_physLoc_intmediatype.xml")))
        expect(generated_xml).to be_equivalent_to(expected_xml).ignoring_attr_values('datetime', 'sourceFile')
      end
    end
  end

  after :all do
    Dir.foreach(@tmp_dir) {|f| File.delete(File.join(@tmp_dir, f)) if f != '.' && f != '..' && !File.directory?(f)}
  end
end
