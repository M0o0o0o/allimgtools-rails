class AddPaddleFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :customer_id, :string
    add_column :users, :subscription_id, :string
    add_column :users, :subscription_plan, :string
    add_column :users, :subscribed_until, :datetime

    add_index :users, :customer_id, unique: true
    add_index :users, :subscription_id, unique: true
  end
end
