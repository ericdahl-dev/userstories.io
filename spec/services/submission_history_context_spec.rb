require "rails_helper"

RSpec.describe SubmissionHistoryContext do
  let(:project) { create(:project) }
  let(:collaborator) { create(:collaborator, name: "swift-penguin-42") }
  let(:submission) do
    create(
      :submission,
      project: project,
      collaborator: collaborator,
      title: "Enable dark mode",
      body: "Users want a theme switch for low-light use in the portal"
    )
  end

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

  describe "#similar_to" do
    it "finds paraphrased duplicates from another collaborator on the same project" do
      other = create(:collaborator, name: "brave-otter-77")
      prior = create(
        :submission,
        project: project,
        collaborator: other,
        title: "Dark mode for portal",
        body: "Add dark theme support in the collaborator portal",
        status: "pending"
      )

      matches = context.similar_to

      expect(matches.map { |match| match[:id] }).to include(prior.id)
      expect(matches.first).to include(
        title: prior.title,
        submitter_label: "brave-otter-77",
        same_collaborator: false,
        relationship: "likely duplicate"
      )
    end

    it "flags same-collaborator resubmissions as repeat submissions" do
      prior = create(
        :submission,
        project: project,
        collaborator: collaborator,
        title: "Dark mode toggle",
        body: "Add dark mode toggle to settings",
        status: "pending"
      )

      matches = context.similar_to.find { |match| match[:id] == prior.id }

      expect(matches[:same_collaborator]).to be true
      expect(matches[:relationship]).to eq("repeat submission")
    end

    it "labels shipped stories as already shipped" do
      other = create(:collaborator)
      shipped = create(
        :submission,
        project: project,
        collaborator: other,
        title: "Dark mode support",
        body: "Theme toggle for the portal UI",
        status: "shipped"
      )

      match = context.similar_to.find { |entry| entry[:id] == shipped.id }

      expect(match[:relationship]).to eq("already shipped")
    end

    it "does not include submissions from other projects" do
      other_project = create(:project)
      other = create(:collaborator)
      cross_project = create(
        :submission,
        project: other_project,
        collaborator: other,
        title: "Dark mode for portal",
        body: "Add dark theme support in the collaborator portal"
      )

      expect(context.similar_to.map { |match| match[:id] }).not_to include(cross_project.id)
    end
  end

  describe "#to_similar_prompt" do
    it "formats detected matches for the LLM prompt" do
      other = create(:collaborator, name: "brave-otter-77")
      create(
        :submission,
        project: project,
        collaborator: other,
        title: "Dark mode for portal",
        body: "Add dark theme support in the collaborator portal",
        status: "accepted"
      )

      prompt = context.to_similar_prompt

      expect(prompt).to include("Dark mode for portal")
      expect(prompt).to include("brave-otter-77")
      expect(prompt).to include("accepted")
    end
  end
end
