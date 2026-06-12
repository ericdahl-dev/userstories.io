require "rails_helper"

RSpec.describe SubmissionSimilarityFinder do
  let(:project) { create(:project) }
  let(:collaborator) { create(:collaborator) }
  let(:submission) do
    create(:submission, project: project, collaborator: collaborator, title: "Dark mode", body: "Night theme")
  end

  subject(:finder) { described_class.new(submission) }

  def normalized_vector(*components)
    vector = Array.new(Submission::EMBEDDING_DIMENSIONS, 0.0)
    components.each_with_index { |value, index| vector[index] = value }
    magnitude = Math.sqrt(vector.sum { |value| value * value })
    vector.map { |value| value / magnitude }
  end

  describe "#similar_entries" do
    it "returns top similar submissions on the same project" do
      submission.update!(embedding: normalized_vector(1.0))

      similar = create(:submission, project: project, title: "Night theme", body: "Dark UI")
      similar.update!(embedding: normalized_vector(1.0, 0.05))

      unrelated = create(:submission, project: project, title: "Export CSV", body: "Download data")
      unrelated.update!(embedding: normalized_vector(0.0, 1.0))

      other_project = create(:project)
      cross = create(:submission, project: other_project, title: "Dark mode elsewhere")
      cross.update!(embedding: normalized_vector(1.0))

      entries = finder.similar_entries(limit: 2)

      expect(entries.map { |e| e[:title] }).to eq([ "Night theme" ])
      expect(entries.first).to include(:similarity_score)
      expect(entries.first[:similarity_score]).to be >= described_class::MIN_SIMILARITY_SCORE
      expect(entries.map { |e| e[:title] }).not_to include("Export CSV", "Dark mode elsewhere", submission.title)
    end

    it "excludes dismissed submissions" do
      submission.update!(embedding: normalized_vector(1.0))
      dismissed = create(:submission, project: project, status: "dismissed", title: "Dismissed")
      dismissed.update!(embedding: normalized_vector(1.0))

      expect(finder.similar_entries.map { |e| e[:title] }).not_to include("Dismissed")
    end

    it "returns an empty array when the submission has no embedding" do
      expect(finder.similar_entries).to eq([])
    end
  end
end
