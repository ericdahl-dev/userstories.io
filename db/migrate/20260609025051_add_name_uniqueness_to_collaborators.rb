class AddNameUniquenessToCollaborators < ActiveRecord::Migration[8.1]
  def change
    add_index :collaborators, :name, unique: true
  end
end
