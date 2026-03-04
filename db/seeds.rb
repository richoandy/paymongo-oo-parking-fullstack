# frozen_string_literal: true

# Example: Create a parking lot with 3 entry points and sample slots
# slot_distances: distance from each entry point (A, B, C)
# slot_sizes: 0=SP, 1=MP, 2=LP
lot = ParkingLotInitializer.call(
  entry_points_count: 3,
  slot_distances: [
    [1, 4, 5],   # Slot 0: SP, distances from A,B,C
    [3, 2, 3],   # Slot 1: MP
    [5, 1, 2],   # Slot 2: LP
    [2, 3, 4],   # Slot 3: SP
    [4, 5, 1]    # Slot 4: LP
  ],
  slot_sizes: [0, 1, 2, 0, 2]
)

puts "Created parking lot #{lot.id} with #{lot.parking_slots.count} slots"
