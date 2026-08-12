class AddInstallmentFieldsToTransactions < ActiveRecord::Migration[7.2]
  def change
    add_column :transactions, :installment_group_id, :string
    add_column :transactions, :installment_number, :integer
    add_column :transactions, :total_installments, :integer

    add_index :transactions, :installment_group_id
  end
end
