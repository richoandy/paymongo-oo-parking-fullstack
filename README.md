# Object Oriented Parking Lot API

A Ruby on Rails API for the Object-Oriented Mall parking allocation system. Assigns the closest available slot to vehicles and calculates fees according to the pricing structure.

## Setup

### API (Rails)
```bash
bundle install
bin/rails db:create db:migrate
bin/rails server
```

### Web app (React)
```bash
cd frontend
npm install
npm run dev
```
Runs at http://localhost:5173. Proxies API requests to the Rails server (ensure it's running on port 3000).

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/up` | Health check |
| POST | `/api/parking_lots` | Create parking lot |
| GET | `/api/parking_lots/:id` | Get parking lot (includes all slots) |
| POST | `/api/parking_lots/:id/park` | Park vehicle |
| POST | `/api/parking_lots/:id/unpark` | Unpark vehicle |
| GET | `/api/parking_lots/:id/vehicle/:identifier/fee` | Get vehicle fee |

See [postman/README.md](postman/README.md) for Postman collection and example requests.

---

# Parking Fee Strategy Matrix

## 1. Base Pricing Structure

| Component | Value | Notes |
|-----------|-------|-------|
| Flat rate | 40 pesos | Applies to first 3 hours (inclusive) |
| Full 24-hour chunk | 5,000 pesos | Per complete 24-hour period |
| Rounding | Round up | 6.4 hours → 7 hours |

### Hourly Rates (by slot size, for hours exceeding first 3)

| Slot Type | Code | Rate (pesos/hour) |
|-----------|------|-------------------|
| Small (SP) | 0 | 20 |
| Medium (MP) | 1 | 60 |
| Large (LP) | 2 | 100 |

---

## 2. Duration vs. Fee by Slot Type

| Duration (hrs) | SP (20/hr) | MP (60/hr) | LP (100/hr) |
|----------------|------------|------------|-------------|
| 1 | 40 | 40 | 40 |
| 2 | 40 | 40 | 40 |
| 3 | 40 | 40 | 40 |
| 4 | 60 | 100 | 140 |
| 5 | 80 | 160 | 240 |
| 6 | 100 | 220 | 340 |
| 24 | 5,000 | 5,000 | 5,000 |
| 25 | 5,040 | 5,040 | 5,040 |
| 48 | 10,000 | 10,000 | 10,000 |

---

## 3. Charge Timing (Immediate)

**Every unpark = immediate charge.** `fee_charged` and amount due are set at unpark.

| Event | Action | Session State |
|-------|--------|---------------|
| **Unpark** | Calculate fee, set `fee_charged` on current session, return amount due | Only the session being closed gets `fee_charged` = amount paid at that exit |
| **Continuous rate** | If chain > 1, amount due = total − already paid | Return 0 when no additional charge |

---

## 4. Continuous vs. Normal Rate Flow

| Returned within 1 hr? | First Unpark | Second Unpark |
|-----------------------|--------------|---------------|
| **Yes** | Pay 40 (1 hr) | Pay 0 (total 40 for 2 hrs, already paid) |
| **No** | Pay 40 (1 hr) | — |

---

## 5. Session State Matrix

| Field | Active (parked) | Unparked |
|-------|-----------------|----------|
| `unparked_at` | nil | Set |
| `fee_charged` | nil | Amount paid at that unpark (per session) |

---

## 6. Example: Continuous Rate

| Time | Action | Chain | Fee Returned |
|------|--------|-------|--------------|
| 9:00 | Park | [S1] | — |
| 10:00 | Unpark | [S1] | 40 (1 hr) |
| 10:30 | Park | — | — |
| 11:00 | Unpark | [S1, S2] | 0 (no additional; total 40 for 2 hrs) |

---

## 7. Scenario: Flat Rate Covers Return Within 1 Hour

1. **First session** – User parks for 1 hour and unparks.
   - Total duration: 1 hour (within flat rate).
   - **Pay 40 pesos** (3-hour flat rate) at unpark.

2. **Same user returns** – Parks again within 1 hour of unparking, stays another 1 hour, then unparks.
   - Combined stay: 2 hours (9:00–11:00).
   - Total fee for 2 hours: 40 pesos (still within flat rate).
   - **Pay 0 pesos** at second unpark – the first session already charged the 3-hour flat rate, which covers the full 2 hours.

**Why?** Return within 1 hour is treated as a single continuous stay. The fee is computed on the full combined duration. Since the user already paid 40 at the first unpark, no additional charge is due at the second unpark.

---

## 8. Key Rules

1. **Immediate charge**: Vehicle always pays when unparking; fee is calculated and paid immediately.
2. **Rounding**: Hours are always rounded up (e.g., 6.4 → 7).
3. **Slot size matters**: Exceeding hourly rate depends on slot type (SP/MP/LP), not vehicle size.
4. **Continuous rate**: Exit + return within 1 hour = charge as single continuous stay (pay at first unpark; additional at second).

---

# Unit Tests

The parking fee logic lives in **pure functions** in `ParkingFeeCalculator` (no database, no side effects) and is covered by unit tests.

## Run tests

```bash
bin/rails test test/services/parking_fee_calculator_test.rb
```

## Test coverage

| Category | Tests | What they verify |
|----------|-------|------------------|
| **First 3 hours flat rate** | 3 tests | 1, 2, 3 hours all cost 40 pesos |
| **Exceeding 3 hours by slot** | 7 tests | SP (20/hr), MP (60/hr), LP (100/hr) for 4–6 hours |
| **24-hour chunks** | 5 tests | 24, 25, 27, 28, 48 hours with flat rate and remainder |
| **Edge cases** | 1 test | 0 or negative hours → 0 pesos |
| **round_hours_up** | 2 tests | 6.4 hrs → 7, minimum 1 hour |
| **Continuous rate** | 4 tests | Single period, two periods within 1 hr (amount_due = 0), abuse prevention (2h59m + 2h59m → 60 additional) |
| **build_continuous_chain** | 2 tests | Gap within window merges, gap over window breaks chain |
| **Empty periods** | 1 test | Returns zeros |

## Highlights

- **Pure functions**: `ParkingFeeCalculator.calculate` and `compute_continuous_fee` take simple inputs and return deterministic outputs; no mocks needed.
- **Abuse prevention**: Tests confirm the continuous rate blocks flat-rate abuse (e.g. 2h59m + 2h59m within 1 hr → 100 total, 60 due).
