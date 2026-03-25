import os
from pathlib import Path

from flask import Flask, abort, jsonify, redirect, request, send_from_directory
from psycopg import connect
from psycopg.types.json import Jsonb
from psycopg.rows import dict_row

from lib_functions_python.auth_google import (
    build_user_payload,
    create_session_jwt,
    exchange_google_code,
    load_google_auth_config,
    verify_google_id_token,
)

DATABASE_URL = os.environ.get("DATABASE_URL")
BASE_DIR = Path(__file__).resolve().parent
WEB_ROOT = (BASE_DIR / "hotel-menu").resolve()
DEFAULT_MENU_ID = "b948064d"

app = Flask(__name__)


def _build_auth_response(google_payload: dict, jwt_secret: str) -> dict:
    user_payload = build_user_payload(google_payload)
    session = create_session_jwt(user_payload, jwt_secret)
    return {
        "token": session["token"],
        "user": user_payload,
        "expiresAt": session["expires_at"],
    }


def _serialize_menu_row(row: dict) -> dict:
    return {
        "id": str(row["id"]),
        "hotel": row["hotel"] or {},
        "categories": row["categories"] or [],
        "categoryAliases": row["category_aliases"] or {},
        "items": row["items"] or [],
        "labels": row["labels"] or {},
        "createdAt": row.get("created_at"),
        "updatedAt": row.get("updated_at"),
    }


def get_menu_from_db(menu_id: str) -> dict:
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

    return _serialize_menu_row(row)


@app.get("/api/menu/<menu_id>")
def get_menu(menu_id: str):
    return jsonify(get_menu_from_db(menu_id))


@app.post("/api/auth/google/login")
def google_login():
    payload = request.get_json(silent=True) or {}
    id_token = payload.get("idToken")
    if not id_token:
        abort(400, description="idToken is required")
    try:
        config = load_google_auth_config()
        google_payload = verify_google_id_token(id_token, config.client_id)
    except ValueError as exc:
        abort(400, description=str(exc))
    return jsonify(_build_auth_response(google_payload, config.jwt_secret))


@app.get("/api/auth/google/callback")
def google_callback():
    code = request.args.get("code")
    if not code:
        abort(400, description="code is required")
    try:
        config = load_google_auth_config()
        token_data = exchange_google_code(code, config)
        id_token = token_data.get("id_token")
        if not id_token:
            abort(400, description="Missing id_token from Google")
        google_payload = verify_google_id_token(id_token, config.client_id)
    except ValueError as exc:
        abort(400, description=str(exc))
    return jsonify(_build_auth_response(google_payload, config.jwt_secret))


@app.get("/api/menus")
def list_all_menus():
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")

    # Optional filter by app_user id
    user_id = request.args.get("userId")

    base_query = """
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
    """

    params: dict[str, object] = {}
    if user_id is not None:
        base_query += "\n        WHERE user_id = %(user_id)s"
        params["user_id"] = int(user_id)

    base_query += "\n        ORDER BY updated_at DESC"

    with connect(DATABASE_URL, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(base_query, params)
            rows = cur.fetchall()

    return jsonify([_serialize_menu_row(row) for row in rows])


@app.post("/api/menus")
def create_menu():
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")
    payload = request.get_json(silent=True) or {}
    hotel = payload.get("hotel")
    categories = payload.get("categories")
    items = payload.get("items")
    user_id = payload.get("userId")
    if hotel is None or categories is None or items is None:
        abort(400, description="hotel, categories, and items are required")
    if user_id is None:
        abort(400, description="userId is required to create a menu")
    query = """
        INSERT INTO menus (
            hotel,
            categories,
            category_aliases,
            items,
            labels,
            user_id,
            created_at,
            updated_at
        ) VALUES (
            %(hotel)s,
            %(categories)s,
            %(category_aliases)s,
            %(items)s,
            %(labels)s,
            %(user_id)s,
            NOW(),
            NOW()
        )
        RETURNING
            id,
            hotel,
            categories,
            category_aliases,
            items,
            labels,
            created_at,
            updated_at
    """
    with connect(DATABASE_URL, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(
                query,
                {
                    "hotel": hotel,
                    "categories": categories,
                    "category_aliases": payload.get("categoryAliases", {}),
                    "items": items,
                    "labels": payload.get("labels", {}),
                    "user_id": int(user_id),
                },
            )
            row = cur.fetchone()
    return jsonify(_serialize_menu_row(row)), 201


@app.get("/api/menus/<menu_id>")
def get_menu_by_id(menu_id: str):
    return jsonify(get_menu_from_db(menu_id))


@app.put("/api/menus/<menu_id>")
def replace_menu(menu_id: str):
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")
    payload = request.get_json(silent=True) or {}
    hotel = payload.get("hotel")
    categories = payload.get("categories")
    items = payload.get("items")
    if hotel is None or categories is None or items is None:
        abort(400, description="hotel, categories, and items are required")
    query = """
        UPDATE menus
        SET
            hotel = %(hotel)s,
            categories = %(categories)s,
            category_aliases = %(category_aliases)s,
            items = %(items)s,
            labels = %(labels)s,
            updated_at = NOW()
        WHERE id::text = %(menu_id)s
           OR hotel->>'id' = %(menu_id)s
           OR hotel->>'menu_id' = %(menu_id)s
           OR hotel->>'slug' = %(menu_id)s
        RETURNING
            id,
            hotel,
            categories,
            category_aliases,
            items,
            labels,
            created_at,
            updated_at
    """
    with connect(DATABASE_URL, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(
                query,
                {
                    "menu_id": menu_id,
                    "hotel": hotel,
                    "categories": categories,
                    "category_aliases": payload.get("categoryAliases", {}),
                    "items": items,
                    "labels": payload.get("labels", {}),
                },
            )
            row = cur.fetchone()
    if not row:
        abort(404, description="Menu not found")
    return jsonify(_serialize_menu_row(row))


@app.patch("/api/menus/<menu_id>")
def update_menu(menu_id: str):
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")
    payload = request.get_json(silent=True) or {}
    fields = []
    values = {"menu_id": menu_id}
    if "hotel" in payload:
        fields.append("hotel = %(hotel)s")
        values["hotel"] = payload.get("hotel")
    if "categories" in payload:
        fields.append("categories = %(categories)s")
        values["categories"] = payload.get("categories")
    if "categoryAliases" in payload:
        fields.append("category_aliases = %(category_aliases)s")
        values["category_aliases"] = payload.get("categoryAliases")
    if "items" in payload:
        fields.append("items = %(items)s")
        values["items"] = payload.get("items")
    if "labels" in payload:
        fields.append("labels = %(labels)s")
        values["labels"] = payload.get("labels")
    if not fields:
        abort(400, description="No updatable fields provided")
    fields.append("updated_at = NOW()")
    query = f"""
        UPDATE menus
        SET {", ".join(fields)}
        WHERE id::text = %(menu_id)s
           OR hotel->>'id' = %(menu_id)s
           OR hotel->>'menu_id' = %(menu_id)s
           OR hotel->>'slug' = %(menu_id)s
        RETURNING
            id,
            hotel,
            categories,
            category_aliases,
            items,
            labels,
            created_at,
            updated_at
    """
    with connect(DATABASE_URL, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(query, values)
            row = cur.fetchone()
    if not row:
        abort(404, description="Menu not found")
    return jsonify(_serialize_menu_row(row))


@app.delete("/api/menus/<menu_id>")
def delete_menu(menu_id: str):
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")
    query = """
        DELETE FROM menus
        WHERE id::text = %(menu_id)s
           OR hotel->>'id' = %(menu_id)s
           OR hotel->>'menu_id' = %(menu_id)s
           OR hotel->>'slug' = %(menu_id)s
    """
    with connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(query, {"menu_id": menu_id})
            if cur.rowcount == 0:
                abort(404, description="Menu not found")
    return jsonify({"status": "deleted"})


def _get_menu_row(menu_id: str) -> dict:
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
        WHERE id::text = %(menu_id)s
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
    return row


def _save_menu_parts(menu_id: str, *, categories=None, items=None):
    query = """
        UPDATE menus
        SET
            categories = COALESCE(%(categories)s::jsonb, categories),
            items = COALESCE(%(items)s::jsonb, items),
            updated_at = NOW()
        WHERE id::text = %(menu_id)s
           OR hotel->>'id' = %(menu_id)s
           OR hotel->>'menu_id' = %(menu_id)s
           OR hotel->>'slug' = %(menu_id)s
        RETURNING
            id,
            hotel,
            categories,
            category_aliases,
            items,
            labels,
            created_at,
            updated_at
    """
    with connect(DATABASE_URL, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(
                query,
                {
                    "menu_id": menu_id,
                    "categories": None if categories is None else Jsonb(categories),
                    "items": None if items is None else Jsonb(items),
                },
            )
            row = cur.fetchone()
    if not row:
        abort(404, description="Menu not found")
    return _serialize_menu_row(row)


@app.post("/api/menus/<menu_id>/items")
def create_menu_item(menu_id: str):
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")
    payload = request.get_json(silent=True) or {}
    item_id = payload.get("id")
    if not item_id:
        abort(400, description="Item id is required")
    row = _get_menu_row(menu_id)
    items = row["items"] or []
    if any(item.get("id") == item_id for item in items):
        abort(409, description="Item already exists")
    items.append(payload)
    return jsonify(_save_menu_parts(menu_id, items=items))


@app.put("/api/menus/<menu_id>/items/<item_id>")
def update_menu_item(menu_id: str, item_id: str):
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")
    payload = request.get_json(silent=True) or {}
    row = _get_menu_row(menu_id)
    items = row["items"] or []
    updated = False
    for idx, item in enumerate(items):
        if item.get("id") == item_id:
            items[idx] = payload
            updated = True
            break
    if not updated:
        abort(404, description="Item not found")
    return jsonify(_save_menu_parts(menu_id, items=items))


@app.delete("/api/menus/<menu_id>/items/<item_id>")
def delete_menu_item(menu_id: str, item_id: str):
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")
    row = _get_menu_row(menu_id)
    items = row["items"] or []
    new_items = [item for item in items if item.get("id") != item_id]
    if len(new_items) == len(items):
        abort(404, description="Item not found")
    return jsonify(_save_menu_parts(menu_id, items=new_items))


@app.post("/api/menus/<menu_id>/categories")
def create_category(menu_id: str):
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")
    payload = request.get_json(silent=True) or {}
    category_id = payload.get("id")
    if not category_id:
        abort(400, description="Category id is required")
    row = _get_menu_row(menu_id)
    categories = row["categories"] or []
    if any(cat.get("id") == category_id for cat in categories):
        abort(409, description="Category already exists")
    categories.append(payload)
    return jsonify(_save_menu_parts(menu_id, categories=categories))


@app.put("/api/menus/<menu_id>/categories/<category_id>")
def update_category(menu_id: str, category_id: str):
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")
    payload = request.get_json(silent=True) or {}
    row = _get_menu_row(menu_id)
    categories = row["categories"] or []
    updated = False
    for idx, cat in enumerate(categories):
        if cat.get("id") == category_id:
            categories[idx] = payload
            updated = True
            break
    if not updated:
        abort(404, description="Category not found")
    return jsonify(_save_menu_parts(menu_id, categories=categories))


@app.delete("/api/menus/<menu_id>/categories/<category_id>")
def delete_category(menu_id: str, category_id: str):
    if not DATABASE_URL:
        abort(500, description="DATABASE_URL is not configured")
    row = _get_menu_row(menu_id)
    categories = row["categories"] or []
    new_categories = [cat for cat in categories if cat.get("id") != category_id]
    if len(new_categories) == len(categories):
        abort(404, description="Category not found")
    return jsonify(_save_menu_parts(menu_id, categories=new_categories))


@app.get("/")
def root():
    return redirect("/api/menus", code=302)


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
