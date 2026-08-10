class CreateCreditCards < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_cards do |t|
      t.string :name, null: false
      t.decimal :limit, precision: 10, scale: 2, default: "0.0", null: false
      t.references :bank_account, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end

    add_index :credit_cards, [ :account_id, :name ], unique: true
  end
end
