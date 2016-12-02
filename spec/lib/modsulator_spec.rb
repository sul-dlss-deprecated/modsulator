RSpec.describe Modsulator do
  describe "#validate_headers" do
    subject { Modsulator.new File.join(FIXTURES_DIR, 'test_002.csv'), 'test_002.csv', template_string: "abc def ghi"}
    let(:template_xml) { "abc def ghi"}
    it "should include headers not in the template string" do
      expect(subject.validate_headers(["abc", "phi"])).not_to include "abc"
      expect(subject.validate_headers(["abc", "phi"])).to include "phi"
    end
  end

  describe "#get_template_spreadsheet" do
    it "should return the correct spreadsheet" do
      downloaded_binary_string = Modsulator.get_template_spreadsheet
      expected_binary_string = IO.read(File.join(File.expand_path("../../../lib/modsulator/", __FILE__), "modsulator_template.xlsx"), mode: 'rb')
      expect(downloaded_binary_string).to eq(expected_binary_string)
    end
  end
end
