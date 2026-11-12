#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# pnpm 11+ (README / CI)
corepack enable
corepack prepare pnpm@11.9.0 --activate

cd "$REPO_ROOT/data-agent-frontend-nuxt"
export NUXT_TELEMETRY_DISABLED=1 CI=true
pnpm install --frozen-lockfile

cd "$REPO_ROOT"
chmod +x mvnw
./mvnw -pl data-agent-management -am package -DskipTests -q
