# OO Parking · Web App

React + TypeScript + Vite frontend for the parking lot API.

## Run

```bash
npm install
npm run dev
```

Ensure the Rails API is running on `http://localhost:3000`. The dev server proxies `/api` and `/up` to it.

## Build

```bash
npm run build
npm run preview  # serve dist/
```

## Features

- Create parking lot or open existing by ID
- Park vehicle (vehicle size, entry point)
- Unpark vehicle (returns fee)
- Check vehicle fee & history (running fee when parked)
- Slot map for lot configuration
