class CreateBankAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_accounts do |t|
      t.string :name, null: false
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end

    add_index :bank_accounts, [ :account_id, :name ], unique: true
  end
end
