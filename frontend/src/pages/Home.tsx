import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../api/client';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Input } from '../components/Input';
import './Home.css';

const SAMPLE_LOT = {
  entry_points_count: 3,
  slot_distances: [
    [1, 4, 5],
    [3, 2, 3],
    [5, 1, 2],
    [2, 3, 4],
    [4, 5, 1],
    [1, 1, 2],
    [2, 2, 1],
  ],
  slot_sizes: [0, 1, 2, 0, 2, 1, 0],
};

export function Home() {
  const navigate = useNavigate();
  const [lotId, setLotId] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleCreate = async () => {
    setError('');
    setLoading(true);
    try {
      const lot = await api.createParkingLot(SAMPLE_LOT);
      navigate(`/lot/${lot.id}`);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create');
    } finally {
      setLoading(false);
    }
  };

  const handleGoToLot = () => {
    setError('');
    const id = parseInt(lotId, 10);
    if (isNaN(id) || id < 1) {
      setError('Enter a valid parking lot ID');
      return;
    }
    navigate(`/lot/${id}`);
  };

  return (
    <div className="home">
      <div className="hero">
        <h1>OO Parking Lot</h1>
        <p className="subtitle">Object-Oriented Mall · Smart slot allocation & fee calculation</p>
      </div>

      <div className="actions">
        <Card title="Create new parking lot">
          <p className="card-desc">Initialize a sample lot with 7 slots and 3 entry points.</p>
          <Button variant="primary" onClick={handleCreate} disabled={loading}>
            {loading ? 'Creating…' : 'Create parking lot'}
          </Button>
        </Card>

        <Card title="Open existing lot">
          <p className="card-desc">Enter a parking lot ID to manage it.</p>
          <div className="row">
            <Input
              label="Parking lot ID"
              type="number"
              min={1}
              placeholder="e.g. 1"
              value={lotId}
              onChange={(e) => setLotId(e.target.value)}
            />
            <Button variant="secondary" onClick={handleGoToLot} style={{ alignSelf: 'flex-end' }}>
              Open
            </Button>
          </div>
        </Card>
      </div>

      {error && <div className="error">{error}</div>}
    </div>
  );
}
