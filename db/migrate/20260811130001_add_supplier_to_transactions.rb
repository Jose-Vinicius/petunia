class AddSupplierToTransactions < ActiveRecord::Migration[8.1]
  def up
    add_reference :transactions, :supplier, foreign_key: true, null: true

    # Backfill default supplier for existing transactions if any exist
    Account.find_each do |account|
      supplier = account.suppliers.find_or_create_by!(name: "Geral")
      Transaction.where(account_id: account.id, supplier_id: nil).update_all(supplier_id: supplier.id)
    end
  end

  def down
    remove_reference :transactions, :supplier, foreign_key: true
  end
end
