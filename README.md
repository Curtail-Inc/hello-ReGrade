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
  `claude plugin marketplace add https://app.regrade.curtail.com/downloads/latest/marketplace.json` then `claude plugin install regrade@regrade --scope user`.

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

## 2. Replay against v2 (the noisy "before")

Substitute the `Recording ID` you noted above for `<RECORDING_ID>`:

```bash
regrade replay --rec-id <RECORDING_ID> --target http://localhost:8002
```

This first replay re-sends the token captured during recording — which v2 no longer
recognizes — so it's deliberately full of `401` noise. That's what you'll clean up next.

## 3. Map the token in Claude Code

Open this repo in Claude Code and say:

> Walk me through my latest ReGrade replay.

Claude — guided by this repo's `CLAUDE.md` — explains each step as it goes. You'll see a
burst of `401`s: the replay is sending the recorded token, but v2 issued a brand-new one at
login. **Mapping that token is the skill this demo teaches.** Claude will create a profile
with **two cooperating rules** — an **id-mapping** that pulls the fresh token from the
`/login` response, and a **header transformation rule** that substitutes it into the
`Authorization: Bearer <token>` header of the later requests — then show you the rules and
ask before creating them. (An id-mapping only *learns* the token; the sensor auto-applies
learned values to URLs and bodies, but a header needs the transformation rule to *apply*
it.)

## 4. Re-replay with your new profile

An id-mapping only takes effect when the requests are *re-issued* through it, so run the
replay again — this time with the profile. (`regrade replay` is a CLI command; applying a
profile to the *existing* replay would only re-label it, not re-send the requests with the
fresh token.)

```bash
regrade replay --rec-id <RECORDING_ID> --profile hello-regrade --target http://localhost:8002
```

Use the profile name Claude created — this walkthrough uses `hello-regrade`.

## 5. The payoff

Back in Claude Code, ask it to analyze the new replay. Now the token matches, the `401`
noise is gone, and **one real delta remains** — Claude will help you read it. That's
ReGrade's whole value: *noise hides signal; a profile removes the noise; the signal appears.*

## How the "versions" differ

`app/store.py` is a single file switched by `APP_VERSION`. Curious what changed between v1
and v2? Look after you've found it with ReGrade — the point is that ReGrade caught it from
**traffic alone**, without reading a line of code.

## License

Apache-2.0.
