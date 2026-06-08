require "rails_helper"

RSpec.describe "Projects", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /projects" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get projects_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns 200" do
        get projects_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /projects/:id" do
    let(:project) { create(:project, user: user) }

    context "when unauthenticated" do
      it "redirects to sign-in" do
        get project_path(project)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as owner" do
      before { sign_in user }

      it "returns 200" do
        get project_path(project)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when authenticated as different user" do
      before { sign_in other_user }

      it "redirects with not-authorized alert" do
        get project_path(project)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /projects" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        post projects_path, params: { project: { name: "My App", github_repo: "owner/repo" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "creates a project and redirects" do
        expect {
          post projects_path, params: { project: { name: "My App", github_repo: "owner/repo" } }
        }.to change(Project, :count).by(1)
        expect(response).to redirect_to(project_path(Project.last))
      end

      it "sets share_token on the created project" do
        post projects_path, params: { project: { name: "My App", github_repo: "owner/repo" } }
        expect(Project.last.share_token).to be_present
      end

      it "associates project with signed-in user" do
        post projects_path, params: { project: { name: "My App", github_repo: "owner/repo" } }
        expect(Project.last.user).to eq(user)
      end

      it "renders new on invalid params" do
        post projects_path, params: { project: { name: "", github_repo: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /projects/:id/rotate_token" do
    let(:project) { create(:project, user: user) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "rotates the share_token" do
        old_token = project.share_token
        post rotate_token_project_path(project)
        expect(project.reload.share_token).not_to eq(old_token)
      end

      it "redirects to project" do
        post rotate_token_project_path(project)
        expect(response).to redirect_to(project_path(project))
      end
    end

    context "when authenticated as different user" do
      before { sign_in other_user }

      it "redirects with not-authorized alert" do
        post rotate_token_project_path(project)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /projects/:id" do
    let!(:project) { create(:project, user: user) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "destroys the project" do
        expect { delete project_path(project) }.to change(Project, :count).by(-1)
      end
    end

    context "when authenticated as different user" do
      before { sign_in other_user }

      it "redirects with not-authorized alert" do
        delete project_path(project)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
