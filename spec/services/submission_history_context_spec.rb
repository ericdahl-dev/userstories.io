require "rails_helper"

RSpec.describe SubmissionHistoryContext do
  let(:project) { create(:project) }
  let(:collaborator) { create(:collaborator) }
  let(:submission) { create(:submission, project: project, collaborator: collaborator) }

  subject(:context) { described_class.new(submission) }

  it "excludes current and dismissed submissions" do
    prior = create(:submission, project: project, title: "Prior story", status: "accepted")
    create(:submission, project: project, status: "dismissed", title: "Dismissed story")

    prompt = context.to_prompt
    expect(prompt).to include(prior.title)
    expect(prompt).not_to include("Dismissed story")
    expect(prompt).not_to include(submission.title)
  end

  it "includes same_collaborator flag" do
    create(:submission, project: project, collaborator: collaborator, title: "Mine")
    other = create(:collaborator)
    create(:submission, project: project, collaborator: other, title: "Theirs")

    entries = context.fetch_entries
    mine = entries.find { |e| e[:title] == "Mine" }
    theirs = entries.find { |e| e[:title] == "Theirs" }

    expect(mine[:same_collaborator]).to be true
    expect(theirs[:same_collaborator]).to be false
  end

  it "prefers semantically similar submissions when embeddings exist" do
    submission.update!(embedding: normalized_vector(1.0))

    similar = create(:submission, project: project, title: "Night theme", body: "Dark UI")
    similar.update!(embedding: normalized_vector(1.0, 0.05))

    unrelated = create(:submission, project: project, title: "Export CSV", body: "Download data")
    unrelated.update!(embedding: normalized_vector(0.0, 1.0))

    entries = context.fetch_entries

    expect(entries.first[:title]).to eq("Night theme")
    expect(entries.first[:similarity_score]).to be_present
    expect(entries.map { |e| e[:title] }).not_to include(unrelated.title)
  end

  def normalized_vector(*components)
    vector = Array.new(Submission::EMBEDDING_DIMENSIONS, 0.0)
    components.each_with_index { |value, index| vector[index] = value }
    magnitude = Math.sqrt(vector.sum { |value| value * value })
    vector.map { |value| value / magnitude }
  end
end
