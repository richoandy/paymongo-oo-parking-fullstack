class CreateParkingLots < ActiveRecord::Migration[8.1]
  def change
    create_table :parking_lots do |t|
      t.integer :entry_points_count, null: false, default: 3

      t.timestamps
    end
  end
end
