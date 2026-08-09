class CreateAccountUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :account_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :role, null: false, default: "owner"

      t.timestamps
    end

    add_index :account_users, [ :user_id, :account_id ], unique: true
  end
end
