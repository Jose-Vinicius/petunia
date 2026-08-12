class AddCompetenceDateToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :competence_date, :date
    add_index :transactions, [:account_id, :competence_date]

    reversible do |dir|
      dir.up do
        execute("UPDATE transactions SET competence_date = date WHERE competence_date IS NULL")
        change_column_null :transactions, :competence_date, false
      end
    end
  end
end
