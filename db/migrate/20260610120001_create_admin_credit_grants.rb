class CreateAdminCreditGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_credit_grants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :granted_by, null: false, foreign_key: { to_table: :users }
      t.integer :amount, null: false
      t.text :reason

      t.timestamps
    end

    add_index :admin_credit_grants, :created_at
  end
end
