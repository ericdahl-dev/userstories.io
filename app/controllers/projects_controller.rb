class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: %i[show edit update destroy rotate_token]

  skip_after_action :verify_authorized, only: :index

  def index
    @projects = policy_scope(Project)
  end

  def show
    authorize @project
  end

  def new
    @project = Project.new
    authorize @project
    @github_repos = fetch_github_repos
  end

  def github_repos
    @project = Project.new
    authorize @project, :create?
    @github_repos = fetch_github_repos
    render partial: "github_repo_field", locals: { project: @project, github_repos: @github_repos, form: nil }
  end

  def create
    @project = current_user.projects.build(project_params)
    authorize @project

    if @project.save
      redirect_to @project, notice: "Project created."
    else
      @github_repos = fetch_github_repos
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @project
  end

  def update
    authorize @project

    if @project.update(project_params)
      redirect_to @project, notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @project
    @project.destroy
    redirect_to projects_path, notice: "Project deleted."
  end

  def rotate_token
    authorize @project
    @project.rotate_share_token!
    redirect_to @project, notice: "Shareable link has been rotated."
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :github_repo)
  end

  def fetch_github_repos
    GithubClient.new(current_user.github_token).repos
  rescue GithubClient::Error
    nil
  end
end
