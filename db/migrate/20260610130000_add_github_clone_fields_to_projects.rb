class AddGithubCloneFieldsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :github_clone_status, :string
    add_column :projects, :github_clone_refreshed_at, :datetime
  end
end
