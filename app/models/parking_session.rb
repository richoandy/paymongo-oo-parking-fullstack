class ParkingSession < ApplicationRecord
  belongs_to :parking_lot
  belongs_to :parking_slot

  validates :vehicle_size, :vehicle_identifier, :entry_point, :parked_at, presence: true
  validates :vehicle_size, inclusion: { in: 0..2 }
end
