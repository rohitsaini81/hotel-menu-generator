#!/usr/bin/env python3
from http import HTTPStatus
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import re
import sys
from urllib.parse import urlparse


MENU_ID_PATTERN = re.compile(r"^[a-zA-Z0-9]{8}$")


def main() -> None:
    server_dir = Path(__file__).resolve().parent
    root = (server_dir.parent / "hotel-menu").resolve()
    if not root.exists() or not root.is_dir():
        raise SystemExit(f"Static directory not found: {root}")

    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000

    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(root), **kwargs)

        def _send_menu_json(self, menu_id: str) -> None:
            if not MENU_ID_PATTERN.fullmatch(menu_id):
                self.send_error(HTTPStatus.NOT_FOUND, "Menu not found")
                return

            menu_file = server_dir / f"{menu_id}.json"
            if not menu_file.is_file():
                self.send_error(HTTPStatus.NOT_FOUND, "Menu not found")
                return

            payload = menu_file.read_bytes()
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        def do_GET(self) -> None:  # noqa: N802 (stdlib method name)
            path = urlparse(self.path).path

            if path.startswith("/api/menu/"):
                menu_id = path.removeprefix("/api/menu/").strip("/")
                if not menu_id or "/" in menu_id:
                    self.send_error(HTTPStatus.NOT_FOUND, "Menu not found")
                    return
                self._send_menu_json(menu_id)
                return

            segments = [segment for segment in path.split("/") if segment]
            if (
                len(segments) == 2
                and segments[0] == "hotel"
                and MENU_ID_PATTERN.fullmatch(segments[1])
            ):
                self.path = "/index.html"
                return super().do_GET()

            if path.startswith("/hotel/"):
                self.send_error(HTTPStatus.NOT_FOUND, "Menu not found")
                return

            return super().do_GET()

    server = HTTPServer(("", port), Handler)
    print(f"Serving {root} at http://localhost:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.server_close()


if __name__ == "__main__":
    main()
