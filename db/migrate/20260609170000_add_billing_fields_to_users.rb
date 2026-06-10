class AddBillingFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :plan, null: false, default: "free"
      t.integer :refinement_usage_count, null: false, default: 0
      t.date :refinement_usage_period_start
      t.boolean :grandfathered_projects, null: false, default: false
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE users
          SET grandfathered_projects = TRUE
          WHERE id IN (
            SELECT user_id FROM projects GROUP BY user_id HAVING COUNT(*) > 1
          )
        SQL
      end
    end
  end
end
