# hotel-menu-generator

Hotel menu system with:
- a web guest menu (`hotel-menu`)
- a Python static/API server (`server`)
- a Flutter admin app (`mobile_admin`)

## Project Structure

- `hotel-menu/`
  - Frontend web app (HTML/CSS/JS) for guests.
  - Reads `menu_id` from URL path: `/hotel/<menu_id>`.
  - Fetches menu data from `/api/menu/<menu_id>`.

- `server/`
  - `server.py`: primary server to run locally.
  - Serves static frontend from `hotel-menu/`.
  - Serves menu JSON API from files named as 8-char IDs (example: `b948064d.json`).
  - `app.py`: optional Flask version (kept for API/hello-world usage).

- `mobile_admin/`
  - Flutter admin app prototype.
  - Uses local bundled JSON (`mobile_admin/data/menu.json`), not the Python server API.

## Requirements

- Python 3.10+ (tested with Python 3.14)
- Optional (for admin app): Flutter SDK

## Run Guest Web Menu (Main Flow)

1. Start the server:

```bash
cd server
python3 server.py 8000
```

2. Open menu in browser:

```text
http://localhost:8000/hotel/b948064d
```

3. API example:

```bash
curl http://127.0.0.1:8000/api/menu/b948064d
```

## How Routing Works

- `GET /hotel/<8-char-id>`
  - Serves the frontend page.
- `GET /api/menu/<8-char-id>`
  - Returns JSON from `server/<id>.json`.
- Any unknown/invalid ID returns `404`.

## Add a New Menu ID

1. Put JSON file inside `server/`.
2. Rename it to exactly 8 alphanumeric chars (example: `a1b2c3d4.json`).
3. Open:

```text
http://localhost:8000/hotel/a1b2c3d4
```

Example commands:

```bash
cd server
cp ../hotel-menu/data/menu.json a1b2c3d4.json
```

## Optional: Run Flask App

From `server/`:

```bash
flask --app app run --debug
```

Default local URL:

```text
http://127.0.0.1:5000/
```

Menu API example on Flask app:

```bash
curl http://127.0.0.1:5000/api/menu/b948064d
```

## Run Mobile Admin (Flutter)

```bash
cd mobile_admin
flutter pub get
flutter run
```

## Notes

- Root `.gitignore` currently ignores:
  - `__pycache__/`
  - `server/__pycache__/`
  - `app.py` filename pattern
