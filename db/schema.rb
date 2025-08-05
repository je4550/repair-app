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

ActiveRecord::Schema[8.0].define(version: 2025_08_05_012045) do
  create_table "appointment_services", force: :cascade do |t|
    t.integer "appointment_id", null: false
    t.integer "service_id", null: false
    t.integer "quantity", default: 1
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id", "service_id"], name: "index_appointment_services_on_appointment_and_service", unique: true
    t.index ["appointment_id"], name: "index_appointment_services_on_appointment_id"
    t.index ["service_id"], name: "index_appointment_services_on_service_id"
  end

  create_table "appointments", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.integer "vehicle_id", null: false
    t.datetime "scheduled_at"
    t.string "status", default: "scheduled"
    t.text "notes"
    t.integer "total_price_cents", default: 0, null: false
    t.string "total_price_currency", default: "USD", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_appointments_on_customer_id"
    t.index ["deleted_at"], name: "index_appointments_on_deleted_at"
    t.index ["scheduled_at"], name: "index_appointments_on_scheduled_at"
    t.index ["status"], name: "index_appointments_on_status"
    t.index ["vehicle_id"], name: "index_appointments_on_vehicle_id"
  end

  create_table "communications", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.string "communication_type"
    t.string "subject"
    t.text "content"
    t.datetime "sent_at"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_communications_on_customer_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.text "notes"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shop_id", null: false
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
    t.index ["email"], name: "index_customers_on_email", unique: true
    t.index ["last_name", "first_name"], name: "index_customers_on_last_name_and_first_name"
    t.index ["phone"], name: "index_customers_on_phone"
    t.index ["shop_id"], name: "index_customers_on_shop_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.integer "appointment_id", null: false
    t.integer "rating"
    t.text "comment"
    t.string "source"
    t.datetime "review_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_reviews_on_appointment_id"
    t.index ["customer_id"], name: "index_reviews_on_customer_id"
  end

  create_table "service_reminders", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.integer "vehicle_id", null: false
    t.integer "service_id", null: false
    t.string "reminder_type"
    t.date "scheduled_date"
    t.string "status"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_service_reminders_on_customer_id"
    t.index ["service_id"], name: "index_service_reminders_on_service_id"
    t.index ["vehicle_id"], name: "index_service_reminders_on_vehicle_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.integer "duration_minutes"
    t.boolean "active", default: true
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shop_id", null: false
    t.index ["active"], name: "index_services_on_active"
    t.index ["deleted_at"], name: "index_services_on_deleted_at"
    t.index ["shop_id", "name"], name: "index_services_on_shop_id_and_name", unique: true
    t.index ["shop_id"], name: "index_services_on_shop_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.string "subdomain", null: false
    t.string "owner_name"
    t.string "phone"
    t.string "email"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_shops_on_active"
    t.index ["email"], name: "index_shops_on_email"
    t.index ["subdomain"], name: "index_shops_on_subdomain", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "role", default: "technician"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shop_id", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["shop_id"], name: "index_users_on_shop_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.string "vin"
    t.string "make"
    t.string "model"
    t.integer "year"
    t.integer "mileage"
    t.string "license_plate"
    t.string "color"
    t.text "notes"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_vehicles_on_customer_id"
    t.index ["deleted_at"], name: "index_vehicles_on_deleted_at"
    t.index ["license_plate"], name: "index_vehicles_on_license_plate"
    t.index ["vin"], name: "index_vehicles_on_vin"
  end

  add_foreign_key "appointment_services", "appointments"
  add_foreign_key "appointment_services", "services"
  add_foreign_key "appointments", "customers"
  add_foreign_key "appointments", "vehicles"
  add_foreign_key "communications", "customers"
  add_foreign_key "customers", "shops"
  add_foreign_key "reviews", "appointments"
  add_foreign_key "reviews", "customers"
  add_foreign_key "service_reminders", "customers"
  add_foreign_key "service_reminders", "services"
  add_foreign_key "service_reminders", "vehicles"
  add_foreign_key "services", "shops"
  add_foreign_key "users", "shops"
  add_foreign_key "vehicles", "customers"
end
