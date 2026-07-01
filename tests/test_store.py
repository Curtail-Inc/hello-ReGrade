import importlib
import pytest


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("APP_VERSION", "1")
    import app.store as store
    importlib.reload(store)
    return store.app.test_client()


def test_login_returns_a_token(client):
    resp = client.post("/login", json={"username": "demo", "password": "demo"})
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["expires_in"] == 3600
    assert isinstance(body["token"], str) and len(body["token"]) >= 16


def test_login_rejects_bad_credentials(client):
    resp = client.post("/login", json={"username": "demo", "password": "wrong"})
    assert resp.status_code == 401


def test_two_logins_return_different_tokens(client):
    a = client.post("/login", json={"username": "demo", "password": "demo"}).get_json()["token"]
    b = client.post("/login", json={"username": "demo", "password": "demo"}).get_json()["token"]
    assert a != b


def _v(monkeypatch, version):
    import importlib
    monkeypatch.setenv("APP_VERSION", str(version))
    import app.store as store
    importlib.reload(store)
    return store.app.test_client()


def _token(client):
    return client.post("/login", json={"username": "demo", "password": "demo"}).get_json()["token"]


def test_products_is_public_and_stable(monkeypatch):
    v1 = _v(monkeypatch, 1).get("/products").get_json()
    v2 = _v(monkeypatch, 2).get("/products").get_json()
    assert v1 == v2  # control: no version difference


def test_orders_requires_auth(monkeypatch):
    client = _v(monkeypatch, 1)
    assert client.get("/orders/1001").status_code == 401


def test_orders_with_token_succeeds(monkeypatch):
    client = _v(monkeypatch, 1)
    tok = _token(client)
    resp = client.get("/orders/1001", headers={"Authorization": f"Bearer {tok}"})
    assert resp.status_code == 200


def test_v1_total_is_correct(monkeypatch):
    client = _v(monkeypatch, 1)
    tok = _token(client)
    body = client.get("/orders/1001", headers={"Authorization": f"Bearer {tok}"}).get_json()
    assert body["total"] == 46.20


def test_v2_total_drops_the_tax(monkeypatch):
    client = _v(monkeypatch, 2)
    tok = _token(client)
    body = client.get("/orders/1001", headers={"Authorization": f"Bearer {tok}"}).get_json()
    assert body["total"] == 42.00


def test_v1_and_v2_differ_only_on_total(monkeypatch):
    c1 = _v(monkeypatch, 1)
    resp1 = c1.get("/orders/1001", headers={"Authorization": f"Bearer {_token(c1)}"})
    c2 = _v(monkeypatch, 2)
    resp2 = c2.get("/orders/1001", headers={"Authorization": f"Bearer {_token(c2)}"})
    assert resp1.status_code == resp2.status_code == 200
    b1 = resp1.get_json()
    b2 = resp2.get_json()
    assert b1.pop("total") != b2.pop("total")
    assert b1 == b2  # every other field identical
