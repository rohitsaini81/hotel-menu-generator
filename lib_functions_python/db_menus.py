"""Database CRUD helpers for the `menus` table.

Assumes PostgreSQL with columns:
- id (uuid or text)
- hotel (jsonb)
- categories (jsonb)
- category_aliases (jsonb)
- items (jsonb)
- labels (jsonb)
- created_at (timestamptz)
- updated_at (timestamptz)
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterable

from psycopg import connect, sql
from psycopg.rows import dict_row


@dataclass(frozen=True)
class MenuRecord:
    id: str
    hotel: dict[str, Any]
    categories: list[dict[str, Any]]
    category_aliases: dict[str, list[str]]
    items: list[dict[str, Any]]
    labels: dict[str, Any]
    created_at: Any
    updated_at: Any


def _normalize_row(row: dict[str, Any]) -> MenuRecord:
    return MenuRecord(
        id=str(row["id"]),
        hotel=row.get("hotel") or {},
        categories=row.get("categories") or [],
        category_aliases=row.get("category_aliases") or {},
        items=row.get("items") or [],
        labels=row.get("labels") or {},
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
    )


def get_menu(database_url: str, menu_id: str) -> MenuRecord | None:
    """Fetch a menu by id or hotel identifiers."""
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

    with connect(database_url, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(query, {"menu_id": menu_id})
            row = cur.fetchone()

    if not row:
        return None
    return _normalize_row(row)


def list_menus(database_url: str, *, limit: int | None = None, offset: int = 0) -> list[MenuRecord]:
    """List menus, newest first."""
    base = sql.SQL(
        """
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
    )

    params: dict[str, Any] = {"offset": offset}
    if limit is None:
        query = base + sql.SQL(" OFFSET %(offset)s")
    else:
        params["limit"] = limit
        query = base + sql.SQL(" LIMIT %(limit)s OFFSET %(offset)s")

    with connect(database_url, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(query, params)
            rows = cur.fetchall()

    return [_normalize_row(row) for row in rows]


def create_menu(
    database_url: str,
    *,
    menu_id: str,
    hotel: dict[str, Any],
    categories: list[dict[str, Any]],
    category_aliases: dict[str, list[str]] | None = None,
    items: list[dict[str, Any]] | None = None,
    labels: dict[str, Any] | None = None,
) -> MenuRecord:
    """Insert a new menu and return the created record."""
    query = """
        INSERT INTO menus (
            id,
            hotel,
            categories,
            category_aliases,
            items,
            labels,
            created_at,
            updated_at
        ) VALUES (
            %(id)s,
            %(hotel)s,
            %(categories)s,
            %(category_aliases)s,
            %(items)s,
            %(labels)s,
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

    payload = {
        "id": menu_id,
        "hotel": hotel,
        "categories": categories,
        "category_aliases": category_aliases or {},
        "items": items or [],
        "labels": labels or {},
    }

    with connect(database_url, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(query, payload)
            row = cur.fetchone()

    return _normalize_row(row)


def update_menu(
    database_url: str,
    *,
    menu_id: str,
    hotel: dict[str, Any] | None = None,
    categories: list[dict[str, Any]] | None = None,
    category_aliases: dict[str, list[str]] | None = None,
    items: list[dict[str, Any]] | None = None,
    labels: dict[str, Any] | None = None,
) -> MenuRecord | None:
    """Update the menu fields provided; returns updated record or None."""
    fields: list[sql.SQL] = []
    values: dict[str, Any] = {"menu_id": menu_id}

    if hotel is not None:
        fields.append(sql.SQL("hotel = %(hotel)s"))
        values["hotel"] = hotel
    if categories is not None:
        fields.append(sql.SQL("categories = %(categories)s"))
        values["categories"] = categories
    if category_aliases is not None:
        fields.append(sql.SQL("category_aliases = %(category_aliases)s"))
        values["category_aliases"] = category_aliases
    if items is not None:
        fields.append(sql.SQL("items = %(items)s"))
        values["items"] = items
    if labels is not None:
        fields.append(sql.SQL("labels = %(labels)s"))
        values["labels"] = labels

    if not fields:
        return get_menu(database_url, menu_id)

    fields.append(sql.SQL("updated_at = NOW()"))
    set_clause = sql.SQL(", ").join(fields)
    query = sql.SQL(
        """
        UPDATE menus
        SET {set_clause}
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
    ).format(set_clause=set_clause)

    with connect(database_url, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(query, values)
            row = cur.fetchone()

    if not row:
        return None
    return _normalize_row(row)


def delete_menu(database_url: str, menu_id: str) -> bool:
    """Delete a menu by id or hotel identifiers; returns True if deleted."""
    query = """
        DELETE FROM menus
        WHERE id::text = %(menu_id)s
           OR hotel->>'id' = %(menu_id)s
           OR hotel->>'menu_id' = %(menu_id)s
           OR hotel->>'slug' = %(menu_id)s
    """

    with connect(database_url) as conn:
        with conn.cursor() as cur:
            cur.execute(query, {"menu_id": menu_id})
            return cur.rowcount > 0


def upsert_menu(
    database_url: str,
    *,
    menu_id: str,
    hotel: dict[str, Any],
    categories: list[dict[str, Any]],
    category_aliases: dict[str, list[str]] | None = None,
    items: list[dict[str, Any]] | None = None,
    labels: dict[str, Any] | None = None,
) -> MenuRecord:
    """Insert or update a menu keyed by id."""
    query = """
        INSERT INTO menus (
            id,
            hotel,
            categories,
            category_aliases,
            items,
            labels,
            created_at,
            updated_at
        ) VALUES (
            %(id)s,
            %(hotel)s,
            %(categories)s,
            %(category_aliases)s,
            %(items)s,
            %(labels)s,
            NOW(),
            NOW()
        )
        ON CONFLICT (id)
        DO UPDATE SET
            hotel = EXCLUDED.hotel,
            categories = EXCLUDED.categories,
            category_aliases = EXCLUDED.category_aliases,
            items = EXCLUDED.items,
            labels = EXCLUDED.labels,
            updated_at = NOW()
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

    payload = {
        "id": menu_id,
        "hotel": hotel,
        "categories": categories,
        "category_aliases": category_aliases or {},
        "items": items or [],
        "labels": labels or {},
    }

    with connect(database_url, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(query, payload)
            row = cur.fetchone()

    return _normalize_row(row)


def bulk_create_menus(
    database_url: str,
    menus: Iterable[dict[str, Any]],
) -> int:
    """Insert many menus; returns inserted row count."""
    query = """
        INSERT INTO menus (
            id,
            hotel,
            categories,
            category_aliases,
            items,
            labels,
            created_at,
            updated_at
        ) VALUES (
            %(id)s,
            %(hotel)s,
            %(categories)s,
            %(category_aliases)s,
            %(items)s,
            %(labels)s,
            NOW(),
            NOW()
        )
    """

    rows = [
        {
            "id": entry["id"],
            "hotel": entry.get("hotel", {}),
            "categories": entry.get("categories", []),
            "category_aliases": entry.get("category_aliases", {}),
            "items": entry.get("items", []),
            "labels": entry.get("labels", {}),
        }
        for entry in menus
    ]

    if not rows:
        return 0

    with connect(database_url) as conn:
        with conn.cursor() as cur:
            cur.executemany(query, rows)
            return cur.rowcount
