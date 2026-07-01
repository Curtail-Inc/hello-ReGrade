# hello-ReGrade

A 15-minute, hands-on introduction to [ReGrade](https://app.regrade.curtail.com). You'll
record traffic from a tiny service, replay it against a "new version," and use **Claude
Code + the ReGrade MCP tools** to map away auth-token noise and uncover a real regression
hiding underneath.

## What you'll need

- **Docker** (for the demo service) and **Python 3** (for the traffic script).
- A **ReGrade account + API key** — sign up at https://app.regrade.curtail.com, install the
  `regrade` sensor from the downloads at https://app.regrade.curtail.com/downloads, and set
  `REGRADE_API_KEY` (or `~/.regrade/key`).
- **Claude Code** with the ReGrade plugin:
  `claude plugin marketplace add Curtail-Inc/Marketplace` then `claude plugin install regrade@regrade`.

## The demo service

Two versions of a small "orders" API:

- **v1** on `http://localhost:8001` — you record against this.
- **v2** on `http://localhost:8002` — you replay against this.

`POST /login` returns a **fresh token every call**. That's the catch this demo is built
around — see below.

```bash
git clone https://github.com/Curtail-Inc/hello-ReGrade
cd hello-ReGrade
docker compose up -d --build
```

## 1. Record traffic against v1

In one terminal, start the sensor proxy in front of v1:

```bash
regrade proxy --target http://localhost:8001 --port 19870
```

In another, generate some traffic *through the proxy*:

```bash
TARGET=http://localhost:19870 ./traffic/generate.sh
```

Stop the proxy (Ctrl-C). Your recording uploads automatically, and the sensor prints a line
like `Recording ID: <uuid>` — note it down, you'll need it for the replay.

## 2. Replay against v2

Substitute the `Recording ID` you noted above for `<RECORDING_ID>`:

```bash
regrade replay --rec-id <RECORDING_ID> --target http://localhost:8002
```

## 3. Analyze it in Claude Code

Open this repo in Claude Code and say:

> Walk me through my latest ReGrade replay.

Claude — guided by this repo's `CLAUDE.md` — will explain each step as it goes. You'll
see a wall of `401`s first: the replay is reusing the token from the recording, but v2
issued a brand-new one. **Mapping that token is the skill this demo teaches.** Claude will
propose an id-mapping (pull the token from the `/login` response, substitute it into later
requests), show you the rule, and ask before applying it.

## 4. The payoff

Once the token is mapped and the `401` noise clears, **one real delta remains** — and
Claude will help you read it. That's ReGrade's whole value: *noise hides signal; a profile
removes the noise; the signal appears.*

## How the "versions" differ

`app/store.py` is a single file switched by `APP_VERSION`. Curious what changed between v1
and v2? Look after you've found it with ReGrade — the point is that ReGrade caught it from
**traffic alone**, without reading a line of code.

## License

Apache-2.0.
