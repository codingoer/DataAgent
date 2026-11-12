#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

BACKEND_SESSION=dataagent_backend
FRONTEND_SESSION=dataagent_frontend

TMUX=(tmux -f /exec-daemon/tmux.portal.conf)

if ! "${TMUX[@]}" has-session -t "$BACKEND_SESSION" 2>/dev/null; then
  "${TMUX[@]}" new-session -d -s "$BACKEND_SESSION" -c "$REPO_ROOT" \
    "export SPRING_PROFILES_ACTIVE=h2; exec ./mvnw -pl data-agent-management spring-boot:run"
fi

echo "Waiting for backend on :8065..."
for _ in $(seq 1 180); do
  if curl -sf -o /dev/null "http://127.0.0.1:8065/v3/api-docs" 2>/dev/null; then
    break
  fi
  sleep 2
done

if ! curl -sf -o /dev/null "http://127.0.0.1:8065/v3/api-docs"; then
  echo "Backend did not become ready; see tmux session $BACKEND_SESSION" >&2
  exit 1
fi

if ! "${TMUX[@]}" has-session -t "$FRONTEND_SESSION" 2>/dev/null; then
  "${TMUX[@]}" new-session -d -s "$FRONTEND_SESSION" -c "$REPO_ROOT/data-agent-frontend-nuxt" \
    "export NUXT_TELEMETRY_DISABLED=1 CI=true; exec pnpm dev --host 0.0.0.0 --port 3000"
fi

echo "Waiting for frontend on :3000..."
for _ in $(seq 1 120); do
  code="$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:3000/" 2>/dev/null || true)"
  if [[ "$code" == "200" || "$code" == "307" ]]; then
    exit 0
  fi
  sleep 2
done

echo "Frontend did not become ready; see tmux session $FRONTEND_SESSION" >&2
exit 1
