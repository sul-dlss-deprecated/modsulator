RSpec.describe Modsulator do
  before :all do
    @tmp_dir      = File.expand_path("../../../tmp", __FILE__)
    Dir.mkdir(@tmp_dir) unless Dir.exist?(@tmp_dir)
    Dir.foreach(@tmp_dir) {|f| fn = File.join(@tmp_dir, f); File.delete(fn) if f != '.' && f != '..' && !File.directory?(fn)}
  end

  describe "generates and validates" do
    {
      'Fitch_Chavez.xlsx' => '36_Fitch_Chavez.xml',
      'Fitch_King.xlsx' => '36_Fitch_King.xml',
      'M1463_AV_manifest.xlsx' => '36_M1463_AV_manifest.xml',
      'Matter_manifest.csv' => '36_Matter_manifest.xml',
      'PosadaSpreadsheet.xlsx' => '36_PosadaSpreadsheet.xml',
      'ars0056_manifest.csv' => '36_ars0056_manifest.xml',
      'manifest_v0174.csv' => '36_manifest_v0174.xml',
      'roman_coins_mods.xlsx' => '36_roman_coins_mods.xml',
      'crowdsourcing_bridget_1.xlsx' => '36_crowdsourcing_bridget_1.xml',
      'crowdsourcing_bridget_2.xlsx' => '36_crowdsourcing_bridget_2.xml',
      'Heckrotte_ChartsOfCoastSurvey.xlsx' => '36_Heckrotte_ChartsOfCoastSurvey.xml',
      'SC1049_metadata.xlsx' => '36_SC1049_metadata.xml',
      'edition_physLoc_intmediatype.xlsx' => '36_edition_physLoc_intmediatype.xml',
      'filled_template_20160711.xlsx' => '36_filled_template_20160711.xml',
      'location_url.xlsx' => '36_location_url.xml',
      'point_coord_test.xlsx' => '36_point_coord_test.xml'
    }.each do |testfile, results_file|
      generated_xml_string = Modsulator.new(File.join(FIXTURES_DIR, testfile), testfile).convert_rows()
      it "converts #{testfile} to valid XML" do
        error_list = Validator.new(File.expand_path("lib/modsulator/modsulator.xsd")).validate_xml_string(generated_xml_string)
        expect(error_list.length()).to eq(0)
      end
      it "generates same XML from #{testfile} as previous modsulator version" do
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
