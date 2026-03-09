#!/usr/bin/env python3
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import sys


def main() -> None:
    root = (Path(__file__).resolve().parent.parent / "hotel-menu").resolve()
    if not root.exists() or not root.is_dir():
        raise SystemExit(f"Static directory not found: {root}")

    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000

    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(root), **kwargs)

    server = HTTPServer(("", port), Handler)
    print(f"Serving {root} at http://localhost:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.server_close()


if __name__ == "__main__":
    main()
