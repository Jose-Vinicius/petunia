class CreateCreditCardInvoicePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_card_invoice_payments do |t|
      t.references :account, null: false, foreign_key: true
      t.references :credit_card, null: false, foreign_key: true
      t.references :bank_account, null: false, foreign_key: true
      t.integer :transaction_id
      t.date :competence_date, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :paid_at, null: false

      t.timestamps
    end

    add_index :credit_card_invoice_payments, [:credit_card_id, :competence_date], name: "idx_card_invoice_payments_on_card_and_competence"
  end
end
