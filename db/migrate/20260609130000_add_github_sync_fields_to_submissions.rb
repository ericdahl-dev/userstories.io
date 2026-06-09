class AddGithubSyncFieldsToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :github_issue_state, :string unless column_exists?(:submissions, :github_issue_state)
    add_column :submissions, :github_issue_summary, :text unless column_exists?(:submissions, :github_issue_summary)
    add_column :submissions, :github_issue_synced_at, :datetime unless column_exists?(:submissions, :github_issue_synced_at)

    add_index :submissions, :github_issue_synced_at unless index_exists?(:submissions, :github_issue_synced_at)
  end
end
