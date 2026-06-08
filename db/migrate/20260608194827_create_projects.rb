class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :github_repo
      t.string :share_token, null: false

      t.timestamps
    end

    add_index :projects, :share_token, unique: true
  end
end
