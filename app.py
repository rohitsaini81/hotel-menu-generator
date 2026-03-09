import os
from pathlib import Path

from flask import Flask, abort, jsonify, redirect, send_from_directory
from psycopg import connect
from psycopg.rows import dict_row

DATABASE_URL = os.environ.get("DATABASE_URL")
BASE_DIR = Path(__file__).resolve().parent
WEB_ROOT = (BASE_DIR / "hotel-menu").resolve()
DEFAULT_MENU_ID = "b948064d"

app = Flask(__name__)


def get_menu_from_db(menu_id: str) -> dict:
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")

    query = """
        SELECT
            hotel,
            categories,
            category_aliases,
            items,
            labels
        FROM menus
        WHERE
            id::text = %(menu_id)s
            OR hotel->>'id' = %(menu_id)s
            OR hotel->>'menu_id' = %(menu_id)s
            OR hotel->>'slug' = %(menu_id)s
        ORDER BY updated_at DESC
        LIMIT 1
    """

    with connect(DATABASE_URL, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(query, {"menu_id": menu_id})
            row = cur.fetchone()

    if not row:
        abort(404, description="Menu not found")

    return {
        "hotel": row["hotel"] or {},
        "categories": row["categories"] or [],
        "categoryAliases": row["category_aliases"] or {},
        "items": row["items"] or [],
        "labels": row["labels"] or {},
    }


@app.get("/api/menu/<menu_id>")
def get_menu(menu_id: str):
    return jsonify(get_menu_from_db(menu_id))


@app.get("/api/menus")
def list_all_menus():
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")

    query = """
        SELECT
            id,
            hotel,
            categories,
            category_aliases,
            items,
            labels,
            created_at,
            updated_at
        FROM menus
        ORDER BY updated_at DESC
    """

    with connect(DATABASE_URL, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(query)
            rows = cur.fetchall()

    return jsonify(rows)


@app.get("/")
def root():
    return redirect(f"/hotel/{DEFAULT_MENU_ID}", code=302)


@app.get("/hotel/<menu_id>")
def hotel_page(menu_id: str):
    get_menu_from_db(menu_id)
    return send_from_directory(WEB_ROOT, "index.html")


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
    app.run(host="0.0.0.0", port=5000, debug=True)
