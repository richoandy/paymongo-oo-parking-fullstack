class ParkingSlot < ApplicationRecord
  belongs_to :parking_lot
  has_many :parking_sessions

  validates :slot_index, :size, :distances, presence: true
  validates :size, inclusion: { in: 0..2 }
end
