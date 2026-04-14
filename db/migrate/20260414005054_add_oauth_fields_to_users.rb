class AddOauthFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :name, :string
    add_column :users, :avatar_url, :string

    add_index :users, [ :provider, :uid ], unique: true

    # OAuth users don't have a password
    change_column_null :users, :password_digest, true
  end
end
