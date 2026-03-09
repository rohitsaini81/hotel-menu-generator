import json
from pathlib import Path

from flask import Flask, abort, jsonify

app = Flask(__name__)
MENU_ID = "b948064d"
MENU_PATH = Path(__file__).resolve().parent / f"{MENU_ID}.json"


@app.get("/")
def hello_world():
    return "Hello, World!"


@app.get("/api/menu/<menu_id>")
def get_menu(menu_id: str):
    if menu_id != MENU_ID or not MENU_PATH.is_file():
        abort(404)
    with MENU_PATH.open("r", encoding="utf-8") as file:
        data = json.load(file)
    return jsonify(data)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
