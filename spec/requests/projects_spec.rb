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

      it "shows a copy button for the shareable portal link" do
        get project_path(project)

        expect(response.body).to include(portal_url(share_token: project.share_token))
        expect(response.body).to include('data-controller="clipboard"')
        expect(response.body).to include('aria-label="Copy portal link to clipboard"')
        expect(response.body).to include("Copied!")
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

      context "when GitHub API succeeds" do
        let(:fake_client) { instance_double(GithubClient) }

        before do
          allow(GithubClient).to receive(:new).and_return(fake_client)
          allow(fake_client).to receive(:repos).and_return(%w[owner/repo-a owner/repo-b])
        end

        it "renders repo select on GET /projects/new" do
          get new_project_path
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("owner/repo-a")
          expect(response.body).to include("owner/repo-b")
          expect(response.body).to include("Refresh list")
        end

        it "refreshes repo list via GET /projects/github_repos" do
          get github_repos_projects_path, headers: { "Turbo-Frame" => "github_repos" }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('turbo-frame id="github_repos"')
          expect(response.body).to include("owner/repo-a")
        end
      end

      context "when GitHub API fails" do
        before do
          allow(GithubClient).to receive(:new).and_raise(GithubClient::Error)
        end

        it "falls back to text input with message" do
          get new_project_path
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("owner/repo")
        end
      end

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

      it "old portal URL returns not_found after rotation" do
        old_token = project.share_token
        post rotate_token_project_path(project)
        get portal_path(share_token: old_token)
        expect(response).to have_http_status(:not_found)
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
