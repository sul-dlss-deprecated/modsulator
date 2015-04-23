require 'spec_helper'
require 'rubygems'

describe Modsulator do
  describe "#validate_headers" do
    subject { Modsulator.new File.join(FIXTURES_DIR, 'test_002.csv'), 'test_002.csv', template_string: "abc def ghi"}
    let(:template_xml) { "abc def ghi"}
    it "should include headers not in the template string" do
      expect(subject.validate_headers(["abc", "phi"])).not_to include "abc"
      expect(subject.validate_headers(["abc", "phi"])).to include "phi"
    end
  end
end
