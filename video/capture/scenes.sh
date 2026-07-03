#!/usr/bin/env bash
# ABOUTME: Renders styled "terminal + Claude Code + ReGrade MCP" scenes for the demo video.
# ABOUTME: Each function prints one beat; VHS records it into a clip. All numbers are real.
set -uo pipefail

DIM=$'\e[38;5;244m'; BOLD=$'\e[1m'; RST=$'\e[0m'
CYAN=$'\e[38;5;117m'; GRN=$'\e[38;5;114m'; YEL=$'\e[38;5;222m'; RED=$'\e[38;5;210m'
MAG=$'\e[38;5;183m'; ORANGE=$'\e[38;5;215m'; BLUE=$'\e[38;5;111m'

# "type" a command at a shell prompt, char by char
cmd() {
  printf '%s ' "${GRN}\$${RST}"
  local s="$1" i
  for ((i=0; i<${#s}; i++)); do printf '%s' "${s:$i:1}"; sleep 0.018; done
  printf '\n'; sleep 0.5
}
out()    { printf '%s\n' "$1"; sleep "${2:-0.35}"; }
user()   { printf '%s\n' "${DIM}› ${1}${RST}"; sleep 0.8; }
claude() { printf '%s %s\n' "${MAG}●${RST}" "$1"; sleep "${2:-0.7}"; }
tool()   { printf '%s %s\n' "${GRN}⏺${RST}" "${DIM}${1}${RST}"; sleep 0.6; }
hr()     { printf '%s\n' "${DIM}────────────────────────────────────────────────────${RST}"; }

# ask(): the customer types a plain-English message into the Claude Code prompt box.
# Renders a rounded input box and types the text char-by-char, keeping the right border aligned.
ask() {
  local text="$1" W=66 i shown pad
  local CUR="${CYAN}▊${RST}"
  printf '\e[?25l'   # hide the terminal cursor so only the styled ▊ caret shows while typing
  printf '  %s╭%s╮%s\n' "$DIM" "$(printf '─%.0s' $(seq 1 $W))" "$RST"
  for ((i=1; i<=${#text}; i++)); do
    shown="${text:0:i}"
    pad=$(( W - 4 - ${#shown} )); (( pad < 0 )) && pad=0
    printf '\r  %s│%s %s❯%s %s%s%*s%s│%s' \
      "$DIM" "$RST" "$CYAN" "$RST" "$shown" "$CUR" "$pad" "" "$DIM" "$RST"
    sleep 0.034
  done
  printf '\n'
  printf '  %s╰%s╯%s\n' "$DIM" "$(printf '─%.0s' $(seq 1 $W))" "$RST"
  printf '\e[?25h'   # restore cursor
  sleep 0.9
}

title() {
  echo; echo; echo
  out "   ${CYAN}${BOLD}hello-ReGrade${RST}" 0.7
  out "   ${DIM}catch behavioral regressions in your API — from traffic alone${RST}" 1.0
  echo
  out "   ${DIM}record  ${BLUE}→${DIM}  replay  ${BLUE}→${DIM}  map the token  ${BLUE}→${DIM}  the real bug appears${RST}" 2.4
}

prereqs() {
  out "${DIM}# one-time setup — free, about two minutes${RST}" 1.2
  echo
  out " ${CYAN}①${RST} Create a free account + copy an API key   ${DIM}app.regrade.curtail.com${RST}" 2.6
  out " ${CYAN}②${RST} Install the sensor   ${DIM}app.regrade.curtail.com/downloads${RST}" 1.8
  cmd "export REGRADE_API_KEY=rg_live_…"
  out " ${CYAN}③${RST} Add the ReGrade tools to Claude Code:" 1.0
  cmd "claude plugin marketplace add https://app.regrade.curtail.com/downloads/latest/marketplace.json"
  cmd "claude plugin install regrade@regrade --scope user"
  out " ${CYAN}④${RST} Connect once:   ${BOLD}/mcp${RST}   ${DIM}→ log in with the same account as your key${RST}" 2.6
  echo
  out "   ${GRN}${BOLD}✓ all set — now the fun part${RST}" 4.0
}

beat02_setup() {
  out "${DIM}# two versions of a tiny orders API — record against v1, replay against v2${RST}" 0.8
  cmd "git clone https://github.com/Curtail-Inc/hello-ReGrade && cd hello-ReGrade"
  cmd "docker compose up -d --build"
  out "${GRN} ✓${RST} Container ${BOLD}hello-regrade-v1${RST}  Started   ${DIM}:8001  (record)${RST}" 0.5
  out "${GRN} ✓${RST} Container ${BOLD}hello-regrade-v2${RST}  Started   ${DIM}:8002  (replay)${RST}" 1.6
}

beat03_record() {
  out "${DIM}# terminal 1: start the sensor proxy in front of v1${RST}" 0.8
  cmd "regrade proxy --target http://localhost:8001 --port 19870"
  out "${DIM}  proxying :19870 → :8001 … recording${RST}" 1.2
  echo
  out "${DIM}# terminal 2: drive traffic through the proxy with the demo's script${RST}" 0.9
  cmd "TARGET=http://localhost:19870 ./traffic/generate.sh"
  out "${BLUE} →${RST} POST /login   ${DIM}(fresh token)${RST}" 0.35
  out "${BLUE} →${RST} GET  /products   ${DIM}(public)${RST}" 0.35
  out "${BLUE} →${RST} GET  /orders/1001   ×3   ${DIM}(Authorization: Bearer)${RST}" 0.6
  out "${GRN} ✓${RST} traffic complete" 1.4
  out "${DIM}  ^C the proxy  ·  finalizing…${RST}" 1.0
  out "${GRN} ✓${RST} Recording ID: ${BOLD}94790bad-a6bb-46f0-91da-a002c0ff3c4f${RST}" 1.2
  out "${GRN} ✓${RST} 7 entries, 1 chunk  ·  uploaded" 4.0
}

beat04_replay() {
  out "${DIM}# replay the recording against v2 — the 'new version'${RST}" 0.8
  cmd "regrade replay --rec-id 94790bad --target http://localhost:8002"
  out "${DIM}  replaying 7 requests…${RST}" 0.8
  out "  Requests with deltas:  ${BOLD}4${RST}" 0.4
  out "  Total deltas:          ${BOLD}${YEL}22${RST}" 0.8
  out "${DIM}  …but most come from a stale token. Let's ask Claude.${RST}" 1.4
}

beat05_noise() {
  out "${DIM}# open the hello-ReGrade repo in Claude Code — or any MCP client — then just ask${RST}" 0.7
  ask "Walk me through my latest ReGrade replay."
  echo
  claude "On it — pulling the delta summary. ${DIM}(ReGrade MCP tool)${RST}"
  tool "summarize_deltas(replay_id: f5f8f9f0…)"
  echo
  out "  ${BOLD}22 differences${RST}   ·   /orders/1001: ${RED}21${RST}    /login: 1" 0.5
  out "  ${RED}status_code_mismatch${RST}   200 ${DIM}→${RST} ${RED}401 Unauthorized${RST}   ×3" 0.4
  out "  ${DIM}missing_field${RST}   \$.total  \$.tax  \$.subtotal  \$.items  \$.id" 0.4
  out "  ${YEL}\$.token${RST}   changed   41bd235d… ${DIM}→${RST} e1454dfc…" 0.9
  echo
  claude "A ${RED}Status Code 401${RST} means ${BOLD}unauthorized${RST} — the server refused it." 2.8
  claude "Every login mints a ${BOLD}brand-new token${RST}, like a fresh key card." 2.8
  claude "Our recording still sends the ${BOLD}old${RST} card, but v2 already retired it —" 2.8
  claude "so each request is turned away and the real order data hides." 2.8
  claude "${BOLD}Not a bug — and not noise. The replay is reusing a token v2 rotated.${RST}" 2.0
  sleep 1.4
}

beat06_map() {
  ask "Can you clear these 401 errors so I can see what changed?"
  echo
  claude "Two cooperating rules. I'll show them before creating anything:"
  echo
  tool "create_id_mapping(source: body, json_path: \$.token, ns: auth_token)"
  out "     ${DIM}learns the fresh token from each /login response${RST}" 0.6
  tool "create_transformation_rule(target: header, Authorization,"
  out "        ${DIM}pattern: Bearer (token), ns: auth_token)${RST}" 0.5
  out "     ${DIM}substitutes the token into the Authorization header on replay${RST}" 0.9
  echo
  ask "Looks right — create them."
  claude "${GRN}✓${RST} Profile ${BOLD}hello-regrade${RST} updated. Re-run the replay"
  claude "  through it and the fresh token goes out in place of the stale one."
  sleep 1.6
}

beat07_rereplay() {
  out "${DIM}# replay again — this time through the profile${RST}" 0.8
  cmd "regrade replay --rec-id 94790bad --profile hello-regrade --target :8002"
  out "${DIM}  substituting the fresh token as requests go out…${RST}" 1.0
  out "  Total deltas:  ${BOLD}${GRN}3${RST}   ${DIM}(was 22)${RST}" 1.2
  out "${DIM}  the 401s are gone — replay adapted.${RST}" 1.8
  echo
  out "${GRN} ✓${RST} Profile ${BOLD}hello-regrade${RST} saved with your app" 1.6
  out "     ${DIM}the mapping rules persist — you don't rebuild them${RST}" 1.8
  out "${GRN} ✓${RST} Reused automatically on every future replay" 1.8
  out "     ${DIM}map a dynamic field once, and it's handled from here on${RST}" 2.2
  out "${DIM}  Back to Claude.${RST}" 1.4
}

beat08_payoff() {
  ask "Now analyze the new replay."
  echo
  claude "Pulling the summary for the profiled replay. ${DIM}(ReGrade MCP tool)${RST}"
  tool "summarize_deltas(replay_id: 2a02e66b…)"
  echo
  out "  ${BOLD}3 differences${RST}   ·   /orders/1001   ·   ${DIM}401s: gone (token adapted)${RST}" 0.7
  echo
  out "  ${ORANGE}\$.total${RST}    ${GRN}46.20${RST}  ${DIM}→${RST}  ${RED}42.00${RST}      ×3" 1.0
  echo
  claude "One real difference remains. v2 ${BOLD}silently stopped adding tax${RST} —"
  claude "the order total dropped from ${GRN}46.20${RST} to ${RED}42.00${RST}."
  claude "${BOLD}ReGrade caught it from traffic alone.${RST}"
  sleep 1.8
}

outro() {
  echo; echo
  out "   ${GRN}${BOLD}✓ one hidden regression, caught from traffic${RST}" 0.9
  echo
  out "   ${CYAN}Try it:${RST}   ${BOLD}github.com/Curtail-Inc/hello-ReGrade${RST}" 0.9
  echo
  out "   ${DIM}record → replay → map → find the bug — with Claude Code + ReGrade${RST}" 2.2
}

printf '\033[2J\033[3J\033[H'   # clear screen + scrollback so the clip starts fresh
"$@"
