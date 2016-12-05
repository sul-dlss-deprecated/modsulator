RSpec.describe ModsulatorSheet do
  describe "#rows" do
    subject { ModsulatorSheet.new File.join(FIXTURES_DIR, "test_002.csv"), "test_002.csv" }

    it "should use the right header row" do
      expect(subject.headers).to include "druid", "sourceId"
    end

    it "should present each row as a hash" do
      row = subject.rows.first
      expect(row["druid"]).to be_nil
      expect(row["sourceId"]).to eq "test:002"
    end
  end
end
