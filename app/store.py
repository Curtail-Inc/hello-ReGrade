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


PRODUCTS = [
    {"id": "SKU-1", "name": "Widget", "price": 21.00},
    {"id": "SKU-2", "name": "Sticker Pack", "price": 0.00},
]

# subtotal 42.00, tax 4.20 (10%); v1 total 46.20, v2 total 42.00 (tax dropped)
ORDERS = {
    "1001": {
        "id": "1001",
        "items": [{"sku": "SKU-1", "name": "Widget", "qty": 2, "price": 21.00}],
        "subtotal": 42.00,
        "tax": 4.20,
    },
}


@app.get("/products")
def products():
    return jsonify(products=PRODUCTS)


@app.get("/orders/<order_id>")
def get_order(order_id):
    if not _is_authed():
        return jsonify(error="unauthorized"), 401
    order = ORDERS.get(order_id)
    if order is None:
        return jsonify(error="not found"), 404
    subtotal, tax = order["subtotal"], order["tax"]
    # v2 regression: the tax line was dropped from the total.
    total = subtotal + tax if current_version() == 1 else subtotal
    return jsonify(
        id=order["id"],
        items=order["items"],
        subtotal=subtotal,
        tax=tax,
        total=round(total, 2),
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8000")))
