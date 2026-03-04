class CreateParkingSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :parking_slots do |t|
      t.references :parking_lot, null: false, foreign_key: true
      t.integer :slot_index
      t.integer :size
      t.json :distances

      t.timestamps
    end
  end
end
