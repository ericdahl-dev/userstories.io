class AddRefinementCreditBalanceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :refinement_credit_balance, :integer, default: 0, null: false
  end
end
