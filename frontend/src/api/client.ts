const BASE = '';

export type ParkingLot = {
  id: number;
  entry_points_count: number;
  slots_count: number;
  parking_slots?: ParkingSlot[];
  created_at: string;
};

export type ParkingSlot = {
  id: number;
  slot_index: number;
  size: number;
  distances: number[];
};

export type ParkResponse = {
  success: boolean;
  slot_id: number;
  slot_index: number;
  parked_at: string;
};

export type UnparkResponse = {
  success: boolean;
  fee: number;
  slot_id: number;
  message?: string;
};

export type VehicleFeeResponse = {
  vehicle_identifier: string;
  status: 'parked' | 'unparked';
  current_session?: {
    slot_id: number;
    slot_index: number;
    parked_at: string;
    running_fee: number;
    message: string;
  };
  history: Array<{
    id: number;
    slot_id: number;
    slot_index: number;
    parked_at: string;
    unparked_at: string;
    fee_charged: number;
  }>;
};

export const api = {
  async createParkingLot(data: {
    entry_points_count: number;
    slot_distances: number[][];
    slot_sizes: number[];
  }): Promise<ParkingLot> {
    const res = await fetch(`${BASE}/api/parking_lots`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || res.statusText);
    }
    return res.json();
  },

  async getParkingLot(id: number): Promise<ParkingLot> {
    const res = await fetch(`${BASE}/api/parking_lots/${id}`);
    if (!res.ok) throw new Error('Failed to fetch parking lot');
    return res.json();
  },

  async park(lotId: number, data: { vehicle_size: string; vehicle_identifier: string; entry_point: number }): Promise<ParkResponse> {
    const res = await fetch(`${BASE}/api/parking_lots/${lotId}/park`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || res.statusText);
    }
    return res.json();
  },

  async unpark(lotId: number, vehicleIdentifier: string): Promise<UnparkResponse> {
    const res = await fetch(`${BASE}/api/parking_lots/${lotId}/unpark`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ vehicle_identifier: vehicleIdentifier }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || res.statusText);
    }
    return res.json();
  },

  async getVehicleFee(lotId: number, vehicleIdentifier: string): Promise<VehicleFeeResponse> {
    const res = await fetch(`${BASE}/api/parking_lots/${lotId}/vehicle/${encodeURIComponent(vehicleIdentifier)}/fee`);
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || res.statusText);
    }
    return res.json();
  },
};
