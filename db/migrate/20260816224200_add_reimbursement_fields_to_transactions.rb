class AddReimbursementFieldsToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :recurring_transactions, :reimbursable, :boolean, default: false, null: false
    add_column :recurring_transactions, :reimbursed, :boolean, default: false, null: false

    add_column :transactions, :reimbursable, :boolean, default: false, null: false
    add_column :transactions, :reimbursed, :boolean, default: false, null: false
    add_column :transactions, :reimbursed_amount, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_index :transactions, [:reimbursable, :reimbursed]
  end
end
