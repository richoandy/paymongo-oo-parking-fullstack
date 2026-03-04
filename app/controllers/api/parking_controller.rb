# frozen_string_literal: true

module Api
  class ParkingController < ApplicationController
    before_action :set_parking_lot

    def park
      session = ParkingService.new(@parking_lot).park(
        vehicle_size: vehicle_size_param,
        vehicle_identifier: params[:vehicle_identifier],
        entry_point: params[:entry_point]
      )
      render json: {
        success: true,
        slot_id: session.parking_slot_id,
        slot_index: session.parking_slot.slot_index,
        parked_at: session.parked_at
      }, status: :created
    rescue ParkingService::NoAvailableSlotError, ParkingService::InvalidVehicleSizeError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def unpark
      result = ParkingService.new(@parking_lot).unpark(
        vehicle_identifier: params[:vehicle_identifier]
      )
      render json: {
        success: true,
        fee: result[:fee],
        slot_id: result[:slot_id],
        message: result[:message]
      }.compact
    rescue ParkingService::VehicleNotFoundError => e
      render json: { error: e.message }, status: :not_found
    end

    def vehicle_fee
      vehicle_identifier = params[:vehicle_identifier]
      sessions = @parking_lot.parking_sessions
        .where(vehicle_identifier: vehicle_identifier)
        .includes(:parking_slot)
        .order(parked_at: :desc)

      return render json: { error: "No parking history found for vehicle" }, status: :not_found if sessions.empty?

      active_session = sessions.find { |s| s.unparked_at.nil? }
      finished_sessions = sessions.select { |s| s.unparked_at.present? }

      response = {
        vehicle_identifier: vehicle_identifier,
        status: active_session ? "parked" : "unparked"
      }

      if active_session
        response[:current_session] = {
          slot_id: active_session.parking_slot_id,
          slot_index: active_session.parking_slot.slot_index,
          parked_at: active_session.parked_at,
          running_fee: ParkingService.calculate_running_fee(active_session),
          message: "Fee if you unpark now"
        }
      end

      response[:history] = finished_sessions.map do |s|
        {
          id: s.id,
          slot_id: s.parking_slot_id,
          slot_index: s.parking_slot.slot_index,
          parked_at: s.parked_at,
          unparked_at: s.unparked_at,
          fee_charged: s.fee_charged
        }
      end

      render json: response
    end

    private

    def set_parking_lot
      @parking_lot = ParkingLot.find(params[:parking_lot_id])
    end

    def vehicle_size_param
      size = params[:vehicle_size]
      return size.to_i if size.is_a?(Numeric)
      return 0 if size.to_s.upcase == "S"
      return 1 if size.to_s.upcase == "M"
      return 2 if size.to_s.upcase == "L"

      size.to_i
    end
  end
end
