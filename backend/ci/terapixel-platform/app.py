import json
import os
import sqlite3
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


DB_PATH = os.environ.get("DB_PATH", "/data/terapixel-platform.db")
GAME_ID = os.environ.get("TPX_GAME_ID", "block_forge")
INTERNAL_SERVICE_KEY = os.environ.get("INTERNAL_SERVICE_KEY", "ci-internal-key")
PORT = int(os.environ.get("PORT", "8080"))


def get_conn():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS players (
            nakama_user_id TEXT PRIMARY KEY,
            player_id TEXT NOT NULL,
            session_token TEXT NOT NULL
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_type TEXT NOT NULL,
            payload_json TEXT NOT NULL
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS coins (
            player_id TEXT PRIMARY KEY,
            balance INTEGER NOT NULL DEFAULT 0
        )
        """
    )
    conn.commit()
    conn.close()


class Handler(BaseHTTPRequestHandler):
    server_version = "TerapixelPlatformMock/1.0"

    def _read_json(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0:
            return {}
        raw = self.rfile.read(length).decode("utf-8")
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return {}

    def _send(self, status, body):
        data = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _ok(self, body):
        self._send(200, body)

    def _unauthorized(self):
        self._send(401, {"ok": False, "error": "unauthorized"})

    def _not_found(self):
        self._send(404, {"ok": False, "error": "not_found"})

    def do_GET(self):  # noqa: N802
        if self.path == "/health":
            self._ok({"ok": True, "service": "terapixel-platform-mock", "game_id": GAME_ID})
            return

        if self.path.startswith("/v1/iap/entitlements"):
            self._ok({"ok": True, "entitlements": []})
            return

        self._not_found()

    def do_POST(self):  # noqa: N802
        if self.path == "/v1/auth/verify":
            payload = self._read_json()
            player_id = payload.get("player_id", "mock-player")
            self._ok({"ok": True, "valid": True, "player_id": player_id})
            return

        if self.path in ("/v1/events", "/v1/telemetry/events"):
            payload = self._read_json()
            conn = get_conn()
            conn.execute(
                "INSERT INTO events(event_type, payload_json) VALUES(?, ?)",
                ("event_batch", json.dumps(payload)),
            )
            conn.commit()
            conn.close()
            self._ok({"ok": True})
            return

        if self.path == "/v1/auth/nakama":
            payload = self._read_json()
            nakama_user_id = payload.get("nakama_user_id", "mock-user")
            player_id = f"player-{nakama_user_id}"
            session_token = f"ci-session-{nakama_user_id}"

            conn = get_conn()
            conn.execute(
                """
                INSERT INTO players(nakama_user_id, player_id, session_token)
                VALUES(?, ?, ?)
                ON CONFLICT(nakama_user_id) DO UPDATE SET
                    player_id=excluded.player_id,
                    session_token=excluded.session_token
                """,
                (nakama_user_id, player_id, session_token),
            )
            conn.commit()
            conn.close()

            self._ok(
                {
                    "ok": True,
                    "player_id": player_id,
                    "session_token": session_token,
                    "game_id": GAME_ID,
                }
            )
            return

        if self.path == "/v1/iap/verify":
            self._ok({"ok": True, "status": "verified", "awarded_coins": 0})
            return

        if self.path == "/v1/iap/coins/adjust":
            payload = self._read_json()
            player_id = payload.get("player_id", "mock-player")
            delta = int(payload.get("delta", 0))

            conn = get_conn()
            cur = conn.cursor()
            cur.execute("INSERT OR IGNORE INTO coins(player_id, balance) VALUES(?, 0)", (player_id,))
            cur.execute("UPDATE coins SET balance = balance + ? WHERE player_id = ?", (delta, player_id))
            cur.execute("SELECT balance FROM coins WHERE player_id = ?", (player_id,))
            row = cur.fetchone()
            conn.commit()
            conn.close()

            self._ok({"ok": True, "player_id": player_id, "balance": int(row["balance"])})
            return

        if self.path in (
            "/v1/account/merge/code",
            "/v1/account/merge/redeem",
            "/v1/account/magic-link/start",
            "/v1/account/magic-link/complete",
        ):
            self._ok({"ok": True})
            return

        if self.path == "/v1/identity/internal/username/validate":
            if self.headers.get("x-admin-key") != INTERNAL_SERVICE_KEY:
                self._unauthorized()
                return
            payload = self._read_json()
            username = payload.get("username", "player")
            self._ok({"ok": True, "username": username, "valid": True, "reason": ""})
            return

        self._not_found()

    def log_message(self, fmt, *args):
        print(f"{self.address_string()} - {fmt % args}")


def main():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    init_db()
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"terapixel-platform mock listening on 0.0.0.0:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
