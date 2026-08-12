class AddClosingDayAndDueDayToCreditCards < ActiveRecord::Migration[8.1]
  def change
    add_column :credit_cards, :closing_day, :integer, default: 25, null: false
    add_column :credit_cards, :due_day, :integer, default: 5, null: false
  end
end
