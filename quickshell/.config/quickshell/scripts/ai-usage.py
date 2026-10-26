#!/usr/bin/env python3
"""Uso de Claude Code como un JSON listo para la cápsula (Ai.qml).

Basado en el colector de Omarchy (bin/omarchy-agent-usage-claude):
- Límites oficiales de la cuenta: GET https://api.anthropic.com/api/oauth/usage con el
  token OAuth de Claude Code (~/.claude/.credentials.json). `five_hour` es la sesión y
  `seven_day` la semana; `utilization` viene en porcentaje (0.6 = 0,6 %).
- Tokens: suma de `message.usage` de los registros ~/.claude/projects/*/*.jsonl.

El endpoint limita las consultas con facilidad: los límites se guardan en caché 15 min
(--force pide de nuevo, como mucho una vez por minuto). El token solo viaja en la cabecera
a api.anthropic.com: nunca se guarda ni se imprime.
"""

from __future__ import annotations

import datetime as dt
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

USAGE_ENDPOINT = "https://api.anthropic.com/api/oauth/usage"
CACHE_SECONDS = 15 * 60
FORCE_MIN_SECONDS = 60

CLAUDE_DIR = Path(os.environ.get("CLAUDE_CONFIG_DIR") or Path.home() / ".claude")
CACHE_FILE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "ai-usage" / "limits.json"

UTC = dt.timezone.utc
FIVE_HOURS = dt.timedelta(hours=5)
SEVEN_DAYS = dt.timedelta(days=7)


def now() -> dt.datetime:
    return dt.datetime.now(UTC)


def parse_time(value) -> dt.datetime | None:
    if value in (None, ""):
        return None
    raw = str(value).strip()
    try:
        if raw.isdigit():
            ts = int(raw)
            return dt.datetime.fromtimestamp(ts / 1000 if ts > 1e12 else ts, UTC)
        return dt.datetime.fromisoformat(raw.replace("Z", "+00:00")).astimezone(UTC)
    except ValueError:
        return None


def read_json(path: Path) -> dict:
    try:
        with open(path) as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


# ------------------------------------------------------------------ cuenta y límites


def credentials() -> tuple[str, str]:
    """(token, plan). El token no sale de este proceso salvo hacia la API."""
    login = read_json(CLAUDE_DIR / ".credentials.json").get("claudeAiOauth")
    if not isinstance(login, dict):
        return "", ""
    plan = str(login.get("subscriptionType") or "")
    plan = plan[:1].upper() + plan[1:]
    tier = str(login.get("rateLimitTier") or "")
    if "max_" in tier:
        plan = (plan or "Max") + " " + tier.split("max_", 1)[1].split("_")[0]
    return str(login.get("accessToken") or ""), plan


def bucket(payload: dict, key: str) -> dict | None:
    b = payload.get(key)
    if not isinstance(b, dict):
        return None
    try:
        percent = min(1.0, max(0.0, float(str(b.get("utilization")).replace("%", "")) / 100.0))
    except ValueError:
        return None
    reset = parse_time(b.get("resets_at"))
    return {"percent": percent, "resetsAt": reset.isoformat() if reset else ""}


def probe(token: str) -> tuple[dict | None, str]:
    """(límites, error)."""
    request = urllib.request.Request(USAGE_ENDPOINT, headers={
        "Authorization": "Bearer " + token,
        "anthropic-beta": "oauth-2025-04-20",
        "Accept": "application/json",
    })
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as error:
        if error.code == 429:
            return None, "Anthropic está limitando las consultas; se muestran los últimos datos."
        if error.code in (401, 403):
            return None, "Sesión de Claude Code caducada: abre Claude Code o ejecuta `claude auth login`."
        return None, f"La API de uso respondió {error.code}."
    except (urllib.error.URLError, TimeoutError, OSError):
        return None, "Sin conexión con la API de uso."
    except ValueError:
        return None, "Respuesta no válida de la API de uso."
    if not isinstance(payload, dict):
        return None, "Respuesta no válida de la API de uso."
    limits = {"session": bucket(payload, "five_hour"), "weekly": bucket(payload, "seven_day")}
    if not limits["session"] and not limits["weekly"]:
        return None, "La API de uso no devolvió límites."
    return limits, ""


def limits(force: bool) -> tuple[dict, bool, float, str]:
    """(límites, en vivo, momento de la medida, error)."""
    cache = read_json(CACHE_FILE)
    age = time.time() - float(cache.get("fetchedAt") or 0)
    if cache.get("limits") and (age < CACHE_SECONDS and not force or age < FORCE_MIN_SECONDS):
        return cache["limits"], True, float(cache["fetchedAt"]), ""

    token, _ = credentials()
    if not token:
        return cache.get("limits") or {}, False, float(cache.get("fetchedAt") or 0), \
            "Sin sesión de Claude Code: ejecuta `claude auth login`."
    fresh, error = probe(token)
    if fresh is None:
        return cache.get("limits") or {}, False, float(cache.get("fetchedAt") or 0), error

    fetched = time.time()
    CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
    tmp = CACHE_FILE.with_suffix(".tmp")
    with open(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
        json.dump({"fetchedAt": fetched, "limits": fresh}, f)
    tmp.replace(CACHE_FILE)
    return fresh, True, fetched, ""


# ------------------------------------------------------------------ tokens locales


def usage_rows() -> list[tuple[dt.datetime, int]]:
    """(momento, tokens) de cada respuesta, sin repetir (los registros duplican líneas)."""
    seen: set[str] = set()
    rows = []
    for path in (CLAUDE_DIR / "projects").glob("*/*.jsonl"):
        try:
            with open(path, errors="replace") as f:
                for line in f:
                    if '"usage"' not in line:
                        continue
                    try:
                        entry = json.loads(line)
                    except ValueError:
                        continue
                    message = entry.get("message")
                    if not isinstance(message, dict) or not isinstance(message.get("usage"), dict):
                        continue
                    key = f"{message.get('id')}:{entry.get('requestId')}"
                    if key in seen:
                        continue
                    seen.add(key)
                    when = parse_time(entry.get("timestamp"))
                    u = message["usage"]
                    tokens = sum(int(u.get(k) or 0) for k in (
                        "input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))
                    if when and tokens:
                        rows.append((when, tokens))
        except OSError:
            continue
    rows.sort()
    return rows


def current_block_start(rows: list[tuple[dt.datetime, int]]) -> dt.datetime | None:
    """Sin límites oficiales: bloque de 5 h que empieza (a la hora en punto) con el primer
    mensaje tras el bloque anterior, como ccusage."""
    start = None
    for when, _ in rows:
        if start is None or when >= start + FIVE_HOURS:
            start = when.replace(minute=0, second=0, microsecond=0)
    return start if start and now() < start + FIVE_HOURS else None


def tokens_since(rows, since: dt.datetime | None) -> int:
    return sum(t for when, t in rows if since and when >= since)


# ------------------------------------------------------------------ registro


def main() -> int:
    force = "--force" in sys.argv[1:]
    lims, live, fetched, error = limits(force)
    _, plan = credentials()
    rows = usage_rows()

    session = dict(lims.get("session") or {"percent": -1, "resetsAt": ""})
    weekly = dict(lims.get("weekly") or {"percent": -1, "resetsAt": ""})

    session_reset = parse_time(session["resetsAt"])
    if session_reset and session_reset > now():
        session_start = session_reset - FIVE_HOURS
    else:
        session_start = current_block_start(rows)
        if session_start and not session_reset:
            session["resetsAt"] = (session_start + FIVE_HOURS).isoformat()
    weekly_reset = parse_time(weekly["resetsAt"])
    weekly_start = weekly_reset - SEVEN_DAYS if weekly_reset else now() - SEVEN_DAYS

    local_midnight = dt.datetime.now().astimezone().replace(hour=0, minute=0, second=0, microsecond=0)
    session["tokens"] = tokens_since(rows, session_start)
    weekly["tokens"] = tokens_since(rows, weekly_start)

    json.dump({
        "plan": plan,
        "session": session,
        "weekly": weekly,
        "today": tokens_since(rows, local_midnight.astimezone(UTC)),
        "live": live,
        "fetchedAt": dt.datetime.fromtimestamp(fetched, UTC).isoformat() if fetched else "",
        "error": error,
    }, sys.stdout)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
