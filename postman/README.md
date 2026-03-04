# Postman Collection - OO Parking Lot API

## Import

1. Open Postman
2. **Import Collection**: File → Import → select `OO-Parking-Lot-API.postman_collection.json`
3. **Import Environment** (optional): File → Import → select `development.postman_environment.json` → set as active

## Usage

1. Start the Rails server: `bin/rails server`
2. Select the "Development" environment (or set `base_url` in collection variables)
3. Run requests in order for a full flow:

### Typical flow

1. **Create Parking Lot** → Save the `id` from response, update `parking_lot_id` variable
2. **Park Vehicle** → Vehicle gets assigned closest slot
3. **Unpark Vehicle** → Returns fee charged (immediate)
4. **Get Vehicle Fee** → Check charged fee for a vehicle

## Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/up` | Health check |
| POST | `/api/parking_lots` | Create parking lot |
| GET | `/api/parking_lots/:id` | Get parking lot |
| POST | `/api/parking_lots/:id/park` | Park vehicle |
| POST | `/api/parking_lots/:id/unpark` | Unpark vehicle |
| GET | `/api/parking_lots/:id/vehicle/:identifier/fee` | Get vehicle fee |

## Variables

- `base_url` - API base URL (default: http://localhost:3000)
- `parking_lot_id` - Parking lot ID (update after create)
- `vehicle_identifier` - License plate / vehicle ID
