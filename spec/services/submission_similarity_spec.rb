require "rails_helper"

RSpec.describe SubmissionSimilarity do
  describe ".score" do
    it "returns high score for near-identical title and body" do
      score = described_class.score(
        "Dark mode toggle",
        "Add a dark mode toggle to the portal settings page",
        "Dark mode toggle",
        "Add dark mode toggle in portal settings"
      )

      expect(score).to be >= described_class::DUPLICATE_THRESHOLD
    end

    it "returns moderate score for paraphrased titles with overlapping intent" do
      score = described_class.score(
        "Enable dark mode",
        "Users want a theme switch for low-light use",
        "Dark mode for portal",
        "Add dark theme support in the collaborator portal"
      )

      expect(score).to be >= described_class::RELATED_THRESHOLD
    end

    it "returns low score for unrelated stories" do
      score = described_class.score(
        "Export to CSV",
        "Download submission history as CSV",
        "Dark mode toggle",
        "Add theme support"
      )

      expect(score).to be < described_class::RELATED_THRESHOLD
    end
  end
end
