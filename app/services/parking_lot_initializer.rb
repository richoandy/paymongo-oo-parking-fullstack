# frozen_string_literal: true

class ParkingLotInitializer
  # Creates a parking lot with the given configuration
  # slot_distances: array of tuples, e.g. [[1, 4, 5], [3, 2, 3], ...]
  # slot_sizes: array of integers, 0=SP, 1=MP, 2=LP
  class InitializationError < StandardError; end

  def self.call(entry_points_count:, slot_distances:, slot_sizes:)
    validate!(entry_points_count, slot_distances, slot_sizes)

    ActiveRecord::Base.transaction do
      lot = ParkingLot.create!(entry_points_count: entry_points_count)

      slot_distances.each_with_index do |distances, index|
        lot.parking_slots.create!(
          slot_index: index,
          size: slot_sizes[index],
          distances: distances
        )
      end

      lot
    end
  end

  def self.validate!(entry_points_count, slot_distances, slot_sizes)
    raise InitializationError, "Entry points must be at least 3" if entry_points_count < 3
    raise InitializationError, "slot_distances and slot_sizes must have same length" if slot_distances.size != slot_sizes.size
    raise InitializationError, "Each distance tuple must match entry_points_count" unless slot_distances.all? { |d| d.size == entry_points_count }
    raise InitializationError, "Slot sizes must be 0, 1, or 2" unless slot_sizes.all? { |s| [0, 1, 2].include?(s) }
  end
end
