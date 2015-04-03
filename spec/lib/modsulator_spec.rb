require 'spec_helper'

describe Modsulator do
  describe "#rows" do
    subject { Modsulator.new File.join(FIXTURES_DIR, "test_002.csv"), template: "" }

    it "should use the right header row" do
      expect(subject.rows.first.keys).to include "druid", "sourceId", "status"
    end

    it "should present each row as a hash" do
      row = subject.rows.first
      expect(row["druid"]).to be_nil
      expect(row["sourceId"]).to eq "test:002"
    end
  end

  describe "#validate_headers" do
    subject { Modsulator.new nil, template: "abc def ghi"}
    let(:template_xml) { "abc def ghi"}
    it "should include headers not in the template string" do
      expect(subject.validate_headers(["abc", "phi"])).not_to include "abc"
      expect(subject.validate_headers(["abc", "phi"])).to include "phi"
    end
  end
end