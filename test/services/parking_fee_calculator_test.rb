# frozen_string_literal: true

require "test_helper"

class ParkingFeeCalculatorTest < ActiveSupport::TestCase
  # --- First 3 hours flat rate ---

  test "1 hour costs 40 pesos (flat rate)" do
    assert_equal 40, ParkingFeeCalculator.calculate(duration_hours: 1, slot_size: 0)
    assert_equal 40, ParkingFeeCalculator.calculate(duration_hours: 1, slot_size: 1)
    assert_equal 40, ParkingFeeCalculator.calculate(duration_hours: 1, slot_size: 2)
  end

  test "2 hours costs 40 pesos (flat rate)" do
    assert_equal 40, ParkingFeeCalculator.calculate(duration_hours: 2, slot_size: 0)
  end

  test "3 hours costs 40 pesos (flat rate)" do
    assert_equal 40, ParkingFeeCalculator.calculate(duration_hours: 3, slot_size: 0)
  end

  # --- Exceeding 3 hours by slot type ---

  test "4 hours SP: 40 + 1*20 = 60" do
    assert_equal 60, ParkingFeeCalculator.calculate(duration_hours: 4, slot_size: 0)
  end

  test "4 hours MP: 40 + 1*60 = 100" do
    assert_equal 100, ParkingFeeCalculator.calculate(duration_hours: 4, slot_size: 1)
  end

  test "4 hours LP: 40 + 1*100 = 140" do
    assert_equal 140, ParkingFeeCalculator.calculate(duration_hours: 4, slot_size: 2)
  end

  test "5 hours SP: 40 + 2*20 = 80" do
    assert_equal 80, ParkingFeeCalculator.calculate(duration_hours: 5, slot_size: 0)
  end

  test "6 hours SP: 40 + 3*20 = 100" do
    assert_equal 100, ParkingFeeCalculator.calculate(duration_hours: 6, slot_size: 0)
  end

  test "6 hours MP: 40 + 3*60 = 220" do
    assert_equal 220, ParkingFeeCalculator.calculate(duration_hours: 6, slot_size: 1)
  end

  test "6 hours LP: 40 + 3*100 = 340" do
    assert_equal 340, ParkingFeeCalculator.calculate(duration_hours: 6, slot_size: 2)
  end

  # --- 24-hour chunks ---

  test "24 hours costs 5000 pesos" do
    assert_equal 5000, ParkingFeeCalculator.calculate(duration_hours: 24, slot_size: 0)
    assert_equal 5000, ParkingFeeCalculator.calculate(duration_hours: 24, slot_size: 1)
    assert_equal 5000, ParkingFeeCalculator.calculate(duration_hours: 24, slot_size: 2)
  end

  test "25 hours: 5000 + 40 (1 hr flat) = 5040" do
    assert_equal 5040, ParkingFeeCalculator.calculate(duration_hours: 25, slot_size: 0)
  end

  test "27 hours: 5000 + 40 (3 hr flat) = 5040" do
    assert_equal 5040, ParkingFeeCalculator.calculate(duration_hours: 27, slot_size: 0)
  end

  test "28 hours: 5000 + 40 + 20 = 5060 (SP)" do
    assert_equal 5060, ParkingFeeCalculator.calculate(duration_hours: 28, slot_size: 0)
  end

  test "48 hours costs 10000 pesos" do
    assert_equal 10000, ParkingFeeCalculator.calculate(duration_hours: 48, slot_size: 0)
  end

  # --- Edge cases ---

  test "0 or negative hours costs 0" do
    assert_equal 0, ParkingFeeCalculator.calculate(duration_hours: 0, slot_size: 0)
    assert_equal 0, ParkingFeeCalculator.calculate(duration_hours: -1, slot_size: 0)
  end

  # --- round_hours_up ---

  test "round_hours_up rounds up" do
    assert_equal 1, ParkingFeeCalculator.round_hours_up(1)
    assert_equal 2, ParkingFeeCalculator.round_hours_up(3601)
    assert_equal 7, ParkingFeeCalculator.round_hours_up(6.4 * 3600)
    assert_equal 1, ParkingFeeCalculator.round_hours_up(0.1 * 3600)
  end

  test "round_hours_up minimum 1 for positive duration" do
    assert_equal 1, ParkingFeeCalculator.round_hours_up(1)
    assert_equal 1, ParkingFeeCalculator.round_hours_up(3599)
  end

  # --- Continuous rate: unpark and park within 1 hour ---

  test "single period: full fee, no previous payment" do
    # 1 hour parked
    periods = [
      { parked_at: 0, unparked_at: 3600, fee_charged: nil }
    ]
    result = ParkingFeeCalculator.compute_continuous_fee(periods: periods, slot_size: 0)
    assert_equal 40, result[:total_fee]
    assert_equal 40, result[:amount_due]
    assert_equal 1, result[:duration_hours]
  end

  test "two periods within 1 hour: merged as continuous, amount_due = total - already_paid" do
    # Park 9:00-10:00 (1 hr), unpark, pay 40. Park 10:30-11:00 (0.5 hr), unpark.
    # Total duration 9:00-11:00 = 2 hrs. Total fee = 40. Already paid 40. Amount due = 0.
    base = 0
    periods = [
      { parked_at: base, unparked_at: base + 3600, fee_charged: 40 },
      { parked_at: base + 5400, unparked_at: base + 7200, fee_charged: nil }
    ]
    result = ParkingFeeCalculator.compute_continuous_fee(periods: periods, slot_size: 0)
    assert_equal 40, result[:total_fee]
    assert_equal 0, result[:amount_due]
    assert_equal 2, result[:duration_hours]
  end

  test "abuse prevention: 2h59m + 2h59m within 1hr gap = 6 hrs, pay 100 total, 60 due" do
    # First stay 2h59m (3 hrs rounded) = 40. Second unpark: total 6 hrs = 100. Already paid 40. Due 60.
    base = 0
    periods = [
      { parked_at: base, unparked_at: base + (2 * 3600 + 59 * 60), fee_charged: 40 },
      { parked_at: base + (2 * 3600 + 59 * 60) + 60, unparked_at: base + (5 * 3600 + 58 * 60) + 60, fee_charged: nil }
    ]
    result = ParkingFeeCalculator.compute_continuous_fee(periods: periods, slot_size: 0)
    assert_equal 100, result[:total_fee]
    assert_equal 60, result[:amount_due]
    assert_equal 6, result[:duration_hours]
  end

  test "gap over 1 hour: only last period counts" do
    base = 0
    periods = [
      { parked_at: base, unparked_at: base + 3600, fee_charged: 40 },
      { parked_at: base + 10_800, unparked_at: base + 14_400, fee_charged: nil }
    ]
    result = ParkingFeeCalculator.compute_continuous_fee(periods: periods, slot_size: 0, window_seconds: 3600)
    assert_equal 40, result[:total_fee]
    assert_equal 40, result[:amount_due]
    assert_equal 1, result[:duration_hours]
  end

  test "build_continuous_chain: gap over window breaks chain" do
    base = 0
    periods = [
      { parked_at: base, unparked_at: base + 3600 },
      { parked_at: base + 7201, unparked_at: base + 10800 }
    ]
    chain = ParkingFeeCalculator.build_continuous_chain(periods, 3600)
    assert_equal 1, chain.size
    assert_equal base + 7201, chain.first[:parked_at]
  end

  test "build_continuous_chain: gap within window merges" do
    base = 0
    periods = [
      { parked_at: base, unparked_at: base + 3600 },
      { parked_at: base + 5400, unparked_at: base + 7200 }
    ]
    chain = ParkingFeeCalculator.build_continuous_chain(periods, 3600)
    assert_equal 2, chain.size
  end

  test "empty periods returns zeros" do
    result = ParkingFeeCalculator.compute_continuous_fee(periods: [], slot_size: 0)
    assert_equal 0, result[:total_fee]
    assert_equal 0, result[:amount_due]
    assert_equal 0, result[:duration_hours]
  end
end
