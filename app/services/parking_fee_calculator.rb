# frozen_string_literal: true

# Pure business logic for parking fee calculation.
# No side effects, no database, no Time.current - deterministic.
#
# Rules:
# - Flat rate 40 pesos for first 3 hours
# - Exceeding hourly rate by slot: SP=20, MP=60, LP=100
# - Full 24-hour chunks: 5,000 pesos each
# - Hours rounded up (6.4 -> 7)
# - Continuous rate: unpark + park within 1 hour = single stay
module ParkingFeeCalculator
  HOURLY_RATES = { 0 => 20, 1 => 60, 2 => 100 }.freeze # SP, MP, LP
  FLAT_RATE = 40
  FLAT_RATE_HOURS = 3
  FULL_DAY_RATE = 5000
  FULL_DAY_HOURS = 24
  CONTINUOUS_WINDOW_SECONDS = 3600

  module_function

  # Calculate fee for a single parking period.
  # @param duration_hours [Integer] Total hours (rounded up externally if needed)
  # @param slot_size [Integer] 0=SP, 1=MP, 2=LP
  # @return [Integer] Fee in pesos
  def calculate(duration_hours:, slot_size:)
    return 0 if duration_hours <= 0

    total = 0

    # Full 24-hour chunks
    full_days = duration_hours / FULL_DAY_HOURS
    total += full_days * FULL_DAY_RATE
    remainder_hours = duration_hours % FULL_DAY_HOURS

    return total if remainder_hours == 0

    # First 3 hours flat rate
    if remainder_hours <= FLAT_RATE_HOURS
      total += FLAT_RATE
    else
      total += FLAT_RATE
      excess_hours = remainder_hours - FLAT_RATE_HOURS
      total += excess_hours * HOURLY_RATES[slot_size]
    end

    total
  end

  # Round duration in seconds up to whole hours.
  # @param duration_seconds [Numeric]
  # @return [Integer]
  def round_hours_up(duration_seconds)
    hours = (duration_seconds / 3600.0).ceil
    hours < 1 ? 1 : hours
  end

  # Continuous rate: compute total fee and amount due for a chain of periods.
  # Periods with gap <= 1 hour are merged; total fee uses slot_size of last period.
  #
  # @param periods [Array<Hash>] Each: { parked_at: Integer (epoch), unparked_at: Integer, fee_charged: Integer|nil }
  #   Sorted by parked_at asc. fee_charged = amount already paid at that unpark.
  # @param slot_size [Integer] Slot size for the last (most recent) period
  # @param window_seconds [Integer] Gap threshold for continuous (default 3600)
  # @return [Hash] { total_fee:, amount_due:, duration_hours: }
  def compute_continuous_fee(periods:, slot_size:, window_seconds: CONTINUOUS_WINDOW_SECONDS)
    return { total_fee: 0, amount_due: 0, duration_hours: 0 } if periods.empty?

    chain = build_continuous_chain(periods, window_seconds)
    start_time = chain.first[:parked_at]
    end_time = chain.last[:unparked_at]
    duration_hours = round_hours_up(end_time - start_time)

    total_fee = calculate(duration_hours: duration_hours, slot_size: slot_size)
    already_paid = chain.sum { |p| p[:fee_charged] || 0 }
    amount_due = total_fee - already_paid

    { total_fee: total_fee, amount_due: amount_due, duration_hours: duration_hours }
  end

  # Build chain of periods where gap between consecutive <= window.
  # Starts from the most recent period and extends backwards.
  # @param periods [Array<Hash>] Sorted by parked_at asc (oldest first)
  def build_continuous_chain(periods, window_seconds)
    return [] if periods.empty?

    chain = [periods.last]

    (periods.size - 2).downto(0) do |i|
      gap = periods[i + 1][:parked_at] - periods[i][:unparked_at]
      break if gap > window_seconds

      chain.unshift(periods[i])
    end

    chain
  end
end
