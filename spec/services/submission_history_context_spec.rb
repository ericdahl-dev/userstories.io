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
end
