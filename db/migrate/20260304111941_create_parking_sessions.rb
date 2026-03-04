class CreateParkingSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :parking_sessions do |t|
      t.references :parking_lot, null: false, foreign_key: true
      t.references :parking_slot, null: false, foreign_key: true
      t.integer :vehicle_size
      t.string :vehicle_identifier
      t.integer :entry_point
      t.datetime :parked_at
      t.datetime :unparked_at
      t.decimal :fee_charged, precision: 10, scale: 2

      t.timestamps
    end
    add_index :parking_sessions, [:parking_lot_id, :vehicle_identifier]
    add_index :parking_sessions, :vehicle_identifier
  end
end
