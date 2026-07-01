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
