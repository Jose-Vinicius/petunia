class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :transaction_type, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :description, null: false
      t.date :date, null: false
      t.references :account, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :cost_center, null: true, foreign_key: true
      t.references :bank_account, null: true, foreign_key: true
      t.references :credit_card, null: true, foreign_key: true

      t.timestamps
    end

    add_index :transactions, [ :account_id, :date ]
    add_index :transactions, [ :account_id, :transaction_type ]
    add_index :transactions, [ :account_id, :category_id ]
  end
end
