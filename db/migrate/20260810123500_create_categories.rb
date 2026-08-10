class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.boolean :default, null: false, default: false
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end

    add_index :categories, [ :account_id, :name ], unique: true
  end
end
