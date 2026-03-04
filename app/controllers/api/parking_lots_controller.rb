# frozen_string_literal: true

module Api
  class ParkingLotsController < ApplicationController
    def create
      lot = ParkingLotInitializer.call(
        entry_points_count: params[:entry_points_count],
        slot_distances: params[:slot_distances],
        slot_sizes: params[:slot_sizes]
      )
      render json: parking_lot_json(lot), status: :created
    rescue ParkingLotInitializer::InitializationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def show
      lot = ParkingLot.find(params[:id])
      render json: parking_lot_json(lot)
    end

    private

    def parking_lot_json(lot)
      {
        id: lot.id,
        entry_points_count: lot.entry_points_count,
        slots_count: lot.parking_slots.count,
        parking_slots: lot.parking_slots.order(:slot_index).map { |slot| parking_slot_json(slot) },
        created_at: lot.created_at
      }
    end

    def parking_slot_json(slot)
      {
        id: slot.id,
        slot_index: slot.slot_index,
        size: slot.size,
        distances: slot.distances
      }
    end
  end
end
