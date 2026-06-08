require "rails_helper"

RSpec.describe "Submissions (developer triage)", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:collaborator) { create(:collaborator) }

  describe "GET /projects/:project_id/submissions" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get project_submissions_path(project)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as project owner" do
      before { sign_in user }

      it "returns 200" do
        get project_submissions_path(project)
        expect(response).to have_http_status(:ok)
      end

      it "shows submissions for the project" do
        submission = create(:submission, project: project, collaborator: collaborator)
        get project_submissions_path(project)
        expect(response.body).to include(submission.title)
      end

      it "does not show submissions from another developer's project" do
        other_project = create(:project, user: other_user)
        other_submission = create(:submission, project: other_project, collaborator: collaborator)
        get project_submissions_path(project)
        expect(response.body).not_to include(other_submission.title)
      end
    end

    context "when authenticated as different developer" do
      before { sign_in other_user }

      it "returns 404 (project not found for this user)" do
        get project_submissions_path(project)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /projects/:project_id/submissions/:id" do
    let(:submission) { create(:submission, project: project, collaborator: collaborator) }

    context "when unauthenticated" do
      it "redirects to sign-in" do
        get project_submission_path(project, submission)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as project owner" do
      before { sign_in user }

      it "returns 200" do
        get project_submission_path(project, submission)
        expect(response).to have_http_status(:ok)
      end

      it "shows full title and body" do
        get project_submission_path(project, submission)
        expect(response.body).to include(submission.title)
        expect(response.body).to include(submission.body)
      end

      it "shows collaborator name" do
        get project_submission_path(project, submission)
        expect(response.body).to include(submission.collaborator.name)
      end
    end
  end

  describe "POST /projects/:project_id/submissions/:id/accept" do
    let(:submission) { create(:submission, project: project, collaborator: collaborator, status: "pending") }
    let(:fake_issue) { double(number: 99, html_url: "https://github.com/owner/repo/issues/99") }
    let(:fake_client) { instance_double(Octokit::Client, create_issue: fake_issue) }

    before do
      allow(Octokit::Client).to receive(:new).and_return(fake_client)
    end

    context "when unauthenticated" do
      it "redirects to sign-in" do
        post accept_project_submission_path(project, submission)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as project owner" do
      before { sign_in user }

      it "transitions submission to accepted" do
        post accept_project_submission_path(project, submission)
        expect(submission.reload.status).to eq("accepted")
      end

      it "stores github_issue_number and github_issue_url" do
        post accept_project_submission_path(project, submission)
        expect(submission.reload.github_issue_number).to eq(99)
        expect(submission.reload.github_issue_url).to eq("https://github.com/owner/repo/issues/99")
      end

      it "redirects to submission with notice" do
        post accept_project_submission_path(project, submission)
        expect(response).to redirect_to(project_submission_path(project, submission))
      end

      it "shows error flash and keeps submission pending on GitHub failure" do
        allow(fake_client).to receive(:create_issue).and_raise(Octokit::Error)
        post accept_project_submission_path(project, submission)
        expect(submission.reload.status).to eq("pending")
        expect(response).to redirect_to(project_submission_path(project, submission))
      end
    end
  end

  describe "POST /projects/:project_id/submissions/:id/dismiss" do
    let(:submission) { create(:submission, project: project, collaborator: collaborator, status: "pending") }

    context "when authenticated as project owner" do
      before { sign_in user }

      it "transitions submission to dismissed" do
        post dismiss_project_submission_path(project, submission)
        expect(submission.reload.status).to eq("dismissed")
      end

      it "redirects to submissions list" do
        post dismiss_project_submission_path(project, submission)
        expect(response).to redirect_to(project_submissions_path(project))
      end
    end

    context "when authenticated as different user" do
      before { sign_in other_user }

      it "returns 404" do
        post dismiss_project_submission_path(project, submission)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /projects/:project_id/submissions/:id/ship" do
    let(:submission) { create(:submission, project: project, collaborator: collaborator, status: "accepted") }

    context "when unauthenticated" do
      it "redirects to sign-in" do
        post ship_project_submission_path(project, submission)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as project owner" do
      before { sign_in user }

      it "transitions to shipped" do
        post ship_project_submission_path(project, submission)
        expect(submission.reload.status).to eq("shipped")
      end

      it "redirects to submission" do
        post ship_project_submission_path(project, submission)
        expect(response).to redirect_to(project_submission_path(project, submission))
      end
    end
  end
end
