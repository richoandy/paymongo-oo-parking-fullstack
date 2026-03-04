# frozen_string_literal: true

class ParkingService
  # Vehicle sizes: 0 = small (S), 1 = medium (M), 2 = large (L)
  # Slot sizes: 0 = small (SP), 1 = medium (MP), 2 = large (LP)
  # S can park in SP, MP, LP; M can park in MP, LP; L can park in LP only

  class ParkingError < StandardError; end
  class NoAvailableSlotError < ParkingError; end
  class VehicleNotFoundError < ParkingError; end
  class InvalidVehicleSizeError < ParkingError; end

  CONTINUOUS_RATE_WINDOW = 1.hour

  def initialize(parking_lot)
    @parking_lot = parking_lot
  end

  def park(vehicle_size:, vehicle_identifier:, entry_point:)
    validate_vehicle_size!(vehicle_size)

    slot = find_available_slot(vehicle_size, entry_point)
    raise NoAvailableSlotError, "No available parking slot for vehicle size #{vehicle_size} at entry point #{entry_point}" unless slot

    ParkingSession.create!(
      parking_lot: @parking_lot,
      parking_slot: slot,
      vehicle_size: vehicle_size,
      vehicle_identifier: vehicle_identifier,
      entry_point: entry_point,
      parked_at: Time.current
    )
  end

  def unpark(vehicle_identifier:)
    active_session = @parking_lot.parking_sessions.find_by(vehicle_identifier: vehicle_identifier, unparked_at: nil)
    raise VehicleNotFoundError, "No active parking session found for vehicle #{vehicle_identifier}" unless active_session

    active_session.update!(unparked_at: Time.current)

    chain = build_continuous_chain(active_session)
    periods = chain.map { |s| { parked_at: s.parked_at.to_i, unparked_at: s.unparked_at.to_i, fee_charged: s.fee_charged } }
    slot_size = chain.last.parking_slot.size
    result = ParkingFeeCalculator.compute_continuous_fee(
      periods: periods,
      slot_size: slot_size,
      window_seconds: CONTINUOUS_RATE_WINDOW
    )

    chain.each { |s| s.update!(fee_charged: result[:total_fee], charge_at: nil) }
    amount_due = result[:amount_due]

    result = { fee: amount_due, slot_id: active_session.parking_slot_id }
    result[:message] = "No additional charge (continuous rate - already paid at previous exit)" if amount_due.zero? && chain.size > 1
    result
  end

  def self.calculate_fee_for_sessions(sessions, slot_size: nil)
    return 0 if sessions.empty?

    slot_size ||= sessions.last.parking_slot.size
    start_time = sessions.min_by(&:parked_at).parked_at
    end_time = sessions.max_by(&:unparked_at).unparked_at
    duration_hours = ParkingFeeCalculator.round_hours_up(end_time - start_time)

    ParkingFeeCalculator.calculate(duration_hours: duration_hours, slot_size: slot_size)
  end

  def self.calculate_running_fee(active_session, now: Time.current)
    return 0 unless active_session&.unparked_at.nil?

    slot_size = active_session.parking_slot.size
    duration_hours = ParkingFeeCalculator.round_hours_up(now - active_session.parked_at)

    ParkingFeeCalculator.calculate(duration_hours: duration_hours, slot_size: slot_size)
  end

  private

  def validate_vehicle_size!(vehicle_size)
    return if [0, 1, 2].include?(vehicle_size)

    raise InvalidVehicleSizeError, "Invalid vehicle size. Use 0 (small), 1 (medium), or 2 (large)"
  end

  def vehicle_can_park_in_slot?(vehicle_size, slot_size)
    case vehicle_size
    when 0 then true # S can park anywhere
    when 1 then slot_size >= 1 # M can park in MP, LP
    when 2 then slot_size >= 2 # L can park in LP only
    else false
    end
  end

  def find_available_slot(vehicle_size, entry_point)
    occupied_slot_ids = @parking_lot.parking_sessions
      .where(unparked_at: nil)
      .pluck(:parking_slot_id)

    @parking_lot.parking_slots
      .where.not(id: occupied_slot_ids)
      .select { |slot| vehicle_can_park_in_slot?(vehicle_size, slot.size) }
      .min_by { |slot| slot.distances[entry_point] }
  end

  def build_continuous_chain(session)
    chain = [session]
    current = session

    loop do
      # Find previous session: same vehicle, unparked before current parked
      prev = @parking_lot.parking_sessions
        .where(vehicle_identifier: current.vehicle_identifier)
        .where.not(unparked_at: nil)
        .where("unparked_at < ?", current.parked_at)
        .order(unparked_at: :desc)
        .first

      break unless prev
      break if (current.parked_at - prev.unparked_at) > CONTINUOUS_RATE_WINDOW

      chain.unshift(prev)
      current = prev
    end

    chain
  end

end
