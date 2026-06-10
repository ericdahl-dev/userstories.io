class AddStripeFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
    end

    add_index :users, :stripe_customer_id, unique: true
    add_index :users, :stripe_subscription_id, unique: true
  end
end
