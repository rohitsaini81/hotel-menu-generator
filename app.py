import os

from flask import Flask, abort, jsonify
from psycopg import connect
from psycopg.rows import dict_row

DATABASE_URL = os.environ.get("DATABASE_URL")

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


@app.get("/")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
