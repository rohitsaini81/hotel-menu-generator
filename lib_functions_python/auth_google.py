"""Helpers for Google OAuth login and JWT issuance."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import os
from typing import Any

import jwt
import requests
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token


@dataclass(frozen=True)
class GoogleAuthConfig:
    client_id: str
    client_secret: str
    callback_url: str
    jwt_secret: str


def load_google_auth_config() -> GoogleAuthConfig:
    client_id = os.environ.get("GOOGLE_CLIENT_ID")
    client_secret = os.environ.get("GOOGLE_CLIENT_SECRET")
    callback_url = os.environ.get("GOOGLE_CALLBACK_URL")
    jwt_secret = os.environ.get("JWT_SECRET")
    missing = [
        name
        for name, value in (
            ("GOOGLE_CLIENT_ID", client_id),
            ("GOOGLE_CLIENT_SECRET", client_secret),
            ("GOOGLE_CALLBACK_URL", callback_url),
            ("JWT_SECRET", jwt_secret),
        )
        if not value
    ]
    if missing:
        raise ValueError(f"Missing required env vars: {', '.join(missing)}")
    return GoogleAuthConfig(
        client_id=client_id,
        client_secret=client_secret,
        callback_url=callback_url,
        jwt_secret=jwt_secret,
    )


def verify_google_id_token(token: str, client_id: str) -> dict[str, Any]:
    try:
        return google_id_token.verify_oauth2_token(
            token,
            google_requests.Request(),
            client_id,
        )
    except Exception as exc:  # pragma: no cover - relies on google auth internals
        raise ValueError("Invalid Google id token") from exc


def exchange_google_code(code: str, config: GoogleAuthConfig) -> dict[str, Any]:
    try:
        response = requests.post(
            "https://oauth2.googleapis.com/token",
            data={
                "code": code,
                "client_id": config.client_id,
                "client_secret": config.client_secret,
                "redirect_uri": config.callback_url,
                "grant_type": "authorization_code",
            },
            timeout=10,
        )
        response.raise_for_status()
        return response.json()
    except requests.RequestException as exc:
        raise ValueError("Failed to exchange Google auth code") from exc


def build_user_payload(google_payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": google_payload.get("sub", ""),
        "email": google_payload.get("email", ""),
        "name": google_payload.get("name", ""),
        "picture": google_payload.get("picture", ""),
    }


def create_session_jwt(user_payload: dict[str, Any], jwt_secret: str) -> dict[str, Any]:
    now = datetime.now(timezone.utc)
    expires = now + timedelta(hours=8)
    token = jwt.encode(
        {
            "sub": user_payload.get("id"),
            "email": user_payload.get("email"),
            "name": user_payload.get("name"),
            "iat": int(now.timestamp()),
            "exp": int(expires.timestamp()),
        },
        jwt_secret,
        algorithm="HS256",
    )
    return {"token": token, "expires_at": expires.isoformat()}
