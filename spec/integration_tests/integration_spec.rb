require 'equivalent-xml'
require 'modsulator'
require 'modsulator/validator'

describe Modsulator do
  before :all do
    @tmp_dir      = File.expand_path("../../../tmp", __FILE__)
    Dir.mkdir(@tmp_dir) unless Dir.exists?(@tmp_dir)
    Dir.foreach(@tmp_dir) {|f| fn = File.join(@tmp_dir, f); File.delete(fn) if f != '.' && f != '..' && !File.directory?(fn)}
  end

  describe "generates and validates" do
    {
      'Fitch_Chavez.xlsx' => 'Fitch_Chavez.xml',
      'Fitch_King.xlsx' => 'Fitch_King.xml',
      'M1463_AV_manifest.xlsx' => 'M1463_AV_manifest.xml',
      'Matter_manifest.csv' => 'Matter_manifest.xml',
      'PosadaSpreadsheet.xlsx' => 'PosadaSpreadsheet.xml',
      'ars0056_manifest.csv' => 'ars0056_manifest.xml',
      'manifest_v0174.csv' => 'manifest_v0174.xml',
      'roman_coins_mods_manifest.csv' => 'roman_coins_mods_manifest.xml',
    }.each do |testfile, results_file|
      it "converts #{testfile} correctly to valid XML" do
        generated_xml_string = Modsulator.new(File.join(FIXTURES_DIR, testfile), testfile).convert_rows()
        error_list = Validator.new(File.expand_path("lib/modsulator/modsulator.xsd")).validate_xml_string(generated_xml_string)
        expect(error_list.length()).to eq(0)

        generated_xml = Nokogiri::XML(generated_xml_string)
        expected_xml = Nokogiri::XML(File.read(File.join(FIXTURES_DIR, results_file)))
        expect(generated_xml).to be_equivalent_to(expected_xml).ignoring_attr_values('datetime')
      end
    end
  end

  after :all do
    Dir.foreach(@tmp_dir) {|f| File.delete(File.join(@tmp_dir, f)) if f != '.' && f != '..' && !File.directory?(f)}
  end
end
