# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_10_125500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "account_users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "role", default: "owner", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["user_id", "account_id"], name: "index_account_users_on_user_id_and_account_id", unique: true
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_bank_accounts_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_bank_accounts_on_account_id"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.boolean "default", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_categories_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_categories_on_account_id"
  end

  create_table "cost_centers", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.boolean "default", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_cost_centers_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_cost_centers_on_account_id"
  end

  create_table "credit_cards", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "bank_account_id", null: false
    t.datetime "created_at", null: false
    t.decimal "limit", precision: 10, scale: 2, default: "0.0", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_credit_cards_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_credit_cards_on_account_id"
    t.index ["bank_account_id"], name: "index_credit_cards_on_bank_account_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "bank_account_id"
    t.bigint "category_id", null: false
    t.bigint "cost_center_id"
    t.datetime "created_at", null: false
    t.bigint "credit_card_id"
    t.date "date", null: false
    t.string "description", null: false
    t.string "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "category_id"], name: "index_transactions_on_account_id_and_category_id"
    t.index ["account_id", "date"], name: "index_transactions_on_account_id_and_date"
    t.index ["account_id", "transaction_type"], name: "index_transactions_on_account_id_and_transaction_type"
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["bank_account_id"], name: "index_transactions_on_bank_account_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["cost_center_id"], name: "index_transactions_on_cost_center_id"
    t.index ["credit_card_id"], name: "index_transactions_on_credit_card_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "account_users", "accounts"
  add_foreign_key "account_users", "users"
  add_foreign_key "bank_accounts", "accounts"
  add_foreign_key "categories", "accounts"
  add_foreign_key "cost_centers", "accounts"
  add_foreign_key "credit_cards", "accounts"
  add_foreign_key "credit_cards", "bank_accounts"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "bank_accounts"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "cost_centers"
  add_foreign_key "transactions", "credit_cards"
end
