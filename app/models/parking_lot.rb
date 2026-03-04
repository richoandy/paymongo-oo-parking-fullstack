class ParkingLot < ApplicationRecord
  has_many :parking_slots, dependent: :destroy
  has_many :parking_sessions, dependent: :destroy

  validates :entry_points_count, presence: true, numericality: { greater_than_or_equal_to: 3 }
end
