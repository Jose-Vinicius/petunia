class AddStatusToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :status, :string
    add_index :transactions, [:account_id, :status]

    reversible do |dir|
      dir.up do
        execute "UPDATE transactions SET status = 'realized' WHERE status IS NULL"
        change_column_null :transactions, :status, false, "realized"
      end
    end
  end
end
