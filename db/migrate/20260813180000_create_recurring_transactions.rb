class CreateRecurringTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :recurring_transactions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :transaction_type, null: false
      t.string :frequency, default: "monthly", null: false
      t.date :start_date, null: false
      t.date :end_date
      t.references :category, null: false, foreign_key: true
      t.references :supplier, foreign_key: true
      t.references :cost_center, foreign_key: true
      t.references :bank_account, foreign_key: true
      t.references :credit_card, foreign_key: true
      t.boolean :is_refund, default: false, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_reference :transactions, :recurring_transaction, foreign_key: true
  end
end
