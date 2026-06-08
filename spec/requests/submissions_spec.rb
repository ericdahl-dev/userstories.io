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
end
