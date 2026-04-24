# block_forge Nakama Backend

Local development:

1. `cd backend/nakama`
2. Set platform env values in `local.yml` (or leave stubs for offline work).
3. `docker compose up --build`

Ports:

- API/socket: `http://localhost:7350`
- Console: `http://localhost:7351` (`admin` / `adminpassword`)

Render deployment:

- Uses `backend/nakama/Dockerfile.render`
- Uses root `render.yaml`
- `render/start.sh` runs migrations, starts Nakama, and reverse proxies console under `/console/`.
