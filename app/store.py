"""Tiny two-version "orders" API for the hello-ReGrade demo.

Switch behavior with APP_VERSION (1 = correct, 2 = has the planted bug).
"""
import os
import secrets

from flask import Flask, jsonify, request

app = Flask(__name__)

_issued_tokens: set[str] = set()


def current_version() -> int:
    """Read the active version at request time so both versions are testable in-process."""
    return int(os.environ.get("APP_VERSION", "1"))


def _issue_token() -> str:
    token = secrets.token_hex(16)
    _issued_tokens.add(token)
    return token


def _is_authed() -> bool:
    header = request.headers.get("Authorization", "")
    if not header.startswith("Bearer "):
        return False
    return header[len("Bearer "):] in _issued_tokens


@app.post("/login")
def login():
    data = request.get_json(silent=True) or {}
    if data.get("username") == "demo" and data.get("password") == "demo":
        return jsonify(token=_issue_token(), expires_in=3600)
    return jsonify(error="invalid credentials"), 401


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8000")))
