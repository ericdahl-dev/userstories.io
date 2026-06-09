class EncryptExistingGithubTokens < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  class MigrationUser < ApplicationRecord
    self.table_name = "users"

    encrypts :github_token
  end

  def up
    MigrationUser.reset_column_information
    MigrationUser.find_each do |user|
      plaintext = user.github_token
      next if plaintext.blank?

      user.update!(github_token: nil)
      user.update!(github_token: plaintext)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
