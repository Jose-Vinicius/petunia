class AddDestinationBankAccountIdToTransactions < ActiveRecord::Migration[7.2]
  def change
    add_reference :transactions, :destination_bank_account, foreign_key: { to_table: :bank_accounts }, null: true
  end
end
