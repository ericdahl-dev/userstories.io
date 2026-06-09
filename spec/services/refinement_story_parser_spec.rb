require "rails_helper"

RSpec.describe RefinementStoryParser do
  describe ".parse" do
    it "extracts title and body from refined story section" do
      markdown = <<~MD
        ## Refined story
        **Title:** Better login flow
        **Details:** As a user, I want SSO.

        ## Similar stories on this project
        None found
      MD

      result = described_class.parse(markdown)
      expect(result[:title]).to eq("Better login flow")
      expect(result[:body]).to eq("As a user, I want SSO.")
    end

    it "returns nil when section is missing" do
      expect(described_class.parse("no refined story here")).to be_nil
    end
  end
end
