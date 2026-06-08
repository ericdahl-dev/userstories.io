class CreateCollaborators < ActiveRecord::Migration[8.1]
  def change
    create_table :collaborators do |t|
      t.string :email
      t.string :name

      t.timestamps
    end
    add_index :collaborators, :email, unique: true
  end
end
