class AddSubmissionEmbeddings < ActiveRecord::Migration[8.1]
  def change
    enable_extension "vector"

    add_column :submissions, :embedding, :vector, limit: 1536
    add_index :submissions, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
