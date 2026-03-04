import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { api, type ParkingLot, type VehicleFeeResponse } from '../api/client';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Input, Select } from '../components/Input';
import './LotView.css';

const SLOT_LABELS = ['Small (SP)', 'Medium (MP)', 'Large (LP)'];

export function LotView() {
  const { id } = useParams();
  const lotId = parseInt(id || '0', 10);
  const [lot, setLot] = useState<ParkingLot | null>(null);
  const [error, setError] = useState('');
  const [vehicleId, setVehicleId] = useState('');
  const [vehicleSize, setVehicleSize] = useState('S');
  const [entryPoint, setEntryPoint] = useState(0);
  const [feeData, setFeeData] = useState<VehicleFeeResponse | null>(null);
  const [unparkResult, setUnparkResult] = useState<{ fee: number; message?: string } | null>(null);

  useEffect(() => {
    if (lotId) {
      api
        .getParkingLot(lotId)
        .then(setLot)
        .catch(() => setError('Parking lot not found'));
    }
  }, [lotId]);

  const handlePark = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setFeeData(null);
    setUnparkResult(null);
    try {
      await api.park(lotId, {
        vehicle_identifier: vehicleId,
        vehicle_size: vehicleSize,
        entry_point: entryPoint,
      });
      setFeeData(null);
      const data = await api.getVehicleFee(lotId, vehicleId);
      setFeeData(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to park');
    }
  };

  const handleUnpark = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setFeeData(null);
    setUnparkResult(null);
    try {
      const res = await api.unpark(lotId, vehicleId);
      setUnparkResult({ fee: res.fee, message: res.message });
      const data = await api.getVehicleFee(lotId, vehicleId);
      setFeeData(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to unpark');
    }
  };

  const handleCheckFee = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setUnparkResult(null);
    try {
      const data = await api.getVehicleFee(lotId, vehicleId);
      setFeeData(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to fetch fee');
      setFeeData(null);
    }
  };

  if (!lot) {
    return (
      <div className="lot-loading">
        {error ? error : 'Loading…'}
      </div>
    );
  }

  const entryPoints = Array.from({ length: lot.entry_points_count }, (_, i) => ({
    value: String(i),
    label: `Entry ${String.fromCharCode(65 + i)}`,
  }));

  return (
    <div className="lot-view">
      <Link to="/" className="back-link">← Dashboard</Link>
      <div className="lot-header">
        <h1>Parking Lot #{lot.id}</h1>
        <p className="lot-meta">
          {lot.slots_count} slots · {lot.entry_points_count} entry points
        </p>
      </div>

      {error && <div className="error error-banner">{error}</div>}

      <div className="lot-grid">
        <Card title="Park vehicle">
          <form onSubmit={handlePark} className="form">
            <Input
              label="Vehicle ID (plate)"
              placeholder="ABC-1234"
              value={vehicleId}
              onChange={(e) => setVehicleId(e.target.value)}
              required
            />
            <Select
              label="Vehicle size"
              options={[
                { value: 'S', label: 'Small (S)' },
                { value: 'M', label: 'Medium (M)' },
                { value: 'L', label: 'Large (L)' },
              ]}
              value={vehicleSize}
              onChange={(e) => setVehicleSize(e.target.value)}
            />
            <Select label="Entry point" options={entryPoints} value={String(entryPoint)} onChange={(e) => setEntryPoint(parseInt(e.target.value, 10))} />
            <Button type="submit" variant="success">
              Park
            </Button>
          </form>
        </Card>

        <Card title="Unpark vehicle">
          <form onSubmit={handleUnpark} className="form">
            <Input
              label="Vehicle ID (plate)"
              placeholder="ABC-1234"
              value={vehicleId}
              onChange={(e) => setVehicleId(e.target.value)}
              required
            />
            <Button type="submit" variant="danger">
              Unpark
            </Button>
          </form>
        </Card>

        <Card title="Check vehicle fee">
          <form onSubmit={handleCheckFee} className="form">
            <Input
              label="Vehicle ID (plate)"
              placeholder="ABC-1234"
              value={vehicleId}
              onChange={(e) => setVehicleId(e.target.value)}
              required
            />
            <Button type="submit" variant="secondary">
              Get fee & history
            </Button>
          </form>
        </Card>
      </div>

      {unparkResult && (
        <Card title="Unpark result" className="result-card">
          <div className="fee-display">
            <span className="fee-label">Fee charged</span>
            <span className="fee-value">₱{unparkResult.fee}</span>
          </div>
          {unparkResult.message && <p className="fee-note">{unparkResult.message}</p>}
        </Card>
      )}

      {feeData && (
        <Card title="Vehicle status & history" className="result-card">
          <div className={`status-badge status-${feeData.status}`}>{feeData.status}</div>
          {feeData.current_session && (
            <div className="current-session">
              <h4>Current session</h4>
              <div className="session-row">
                <span>Slot #{feeData.current_session.slot_index}</span>
                <span>Running fee: ₱{feeData.current_session.running_fee}</span>
              </div>
              <p className="session-note">{feeData.current_session.message}</p>
            </div>
          )}
          {feeData.history.length > 0 && (
            <div className="history">
              <h4>History</h4>
              <ul>
                {feeData.history.map((h) => (
                  <li key={h.id}>
                    <span className="mono">
                      Slot #{h.slot_index} · ₱{h.fee_charged}
                    </span>
                    <span className="history-time">
                      {new Date(h.parked_at).toLocaleString()} → {new Date(h.unparked_at).toLocaleString()}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </Card>
      )}

      {lot.parking_slots && lot.parking_slots.length > 0 && (
        <Card title="Slot map">
          <div className="slot-grid">
            {lot.parking_slots.map((s) => (
              <div key={s.id} className="slot-card">
                <span className="slot-index">#{s.slot_index}</span>
                <span className="slot-size">{SLOT_LABELS[s.size]}</span>
                <span className="slot-dists mono">
                  [{s.distances.join(', ')}]
                </span>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}
