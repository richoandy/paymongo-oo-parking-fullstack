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

ActiveRecord::Schema[8.1].define(version: 2026_03_04_112128) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "parking_lots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "entry_points_count", default: 3, null: false
    t.datetime "updated_at", null: false
  end

  create_table "parking_sessions", force: :cascade do |t|
    t.datetime "charge_at"
    t.datetime "created_at", null: false
    t.integer "entry_point"
    t.decimal "fee_charged", precision: 10, scale: 2
    t.datetime "parked_at"
    t.integer "parking_lot_id", null: false
    t.integer "parking_slot_id", null: false
    t.datetime "unparked_at"
    t.datetime "updated_at", null: false
    t.string "vehicle_identifier"
    t.integer "vehicle_size"
    t.index ["parking_lot_id", "vehicle_identifier"], name: "idx_on_parking_lot_id_vehicle_identifier_147c72f583"
    t.index ["parking_lot_id"], name: "index_parking_sessions_on_parking_lot_id"
    t.index ["parking_slot_id"], name: "index_parking_sessions_on_parking_slot_id"
    t.index ["vehicle_identifier"], name: "index_parking_sessions_on_vehicle_identifier"
  end

  create_table "parking_slots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "distances"
    t.integer "parking_lot_id", null: false
    t.integer "size"
    t.integer "slot_index"
    t.datetime "updated_at", null: false
    t.index ["parking_lot_id"], name: "index_parking_slots_on_parking_lot_id"
  end

  add_foreign_key "parking_sessions", "parking_lots"
  add_foreign_key "parking_sessions", "parking_slots"
  add_foreign_key "parking_slots", "parking_lots"
end
