import json
from pathlib import Path
import re

from flask import Flask, abort, jsonify, redirect, send_from_directory

BASE_DIR = Path(__file__).resolve().parent
WEB_ROOT = (BASE_DIR.parent / "hotel-menu").resolve()
MENU_ID_PATTERN = re.compile(r"^[a-zA-Z0-9]{8}$")
DEFAULT_MENU_ID = "b948064d"

app = Flask(__name__)


def resolve_menu_file(menu_id: str) -> Path:
    if not MENU_ID_PATTERN.fullmatch(menu_id):
        abort(404, description="Menu not found")

    menu_file = BASE_DIR / f"{menu_id}.json"
    if not menu_file.is_file():
        abort(404, description="Menu not found")
    return menu_file


@app.get("/")
def root():
    return redirect(f"/hotel/{DEFAULT_MENU_ID}", code=302)


@app.get("/hotel/<menu_id>")
def hotel_page(menu_id: str):
    resolve_menu_file(menu_id)
    return send_from_directory(WEB_ROOT, "index.html")


@app.get("/api/menu/<menu_id>")
def get_menu(menu_id: str):
    menu_file = resolve_menu_file(menu_id)
    with menu_file.open("r", encoding="utf-8") as file:
        data = json.load(file)
    return jsonify(data)


@app.get("/css/<path:filename>")
def serve_css(filename: str):
    return send_from_directory(WEB_ROOT / "css", filename)


@app.get("/js/<path:filename>")
def serve_js(filename: str):
    return send_from_directory(WEB_ROOT / "js", filename)


@app.get("/index.html")
def serve_index():
    return send_from_directory(WEB_ROOT, "index.html")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
