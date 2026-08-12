class AddIsRefundToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :is_refund, :boolean, default: false, null: false
    add_index :transactions, :is_refund
  end
end
