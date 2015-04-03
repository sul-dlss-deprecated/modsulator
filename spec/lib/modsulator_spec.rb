require 'spec_helper'

describe Modsulator do
  describe "#validate_headers" do
    let(:template_xml) { "abc def ghi"}
    it "should include headers not in the template string" do
      expect(subject.validate_headers(["abc", "phi"], template_xml)).not_to include "abc"
      expect(subject.validate_headers(["abc", "phi"], template_xml)).to include "phi"
    end
  end
end