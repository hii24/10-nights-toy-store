#!/usr/bin/env bash
# init.sh — сетап + сборка + смоук-тест. Запускать в начале каждой сессии.
set -euo pipefail

echo "==> [1/4] Toolchain (Rokit)"
if command -v rokit >/dev/null 2>&1; then
  rokit install --no-trust-check   # неинтерактивно: без trust-промптов (CI/агенты)
else
  echo "WARN: rokit не найден — установи Rokit (см. README)"
fi

echo "==> [2/4] Зависимости (Wally)"
if command -v wally >/dev/null 2>&1; then
  wally install
else
  echo "WARN: wally не найден — ставится через Rokit"
fi

echo "==> [3/4] Lint + Build"
command -v selene >/dev/null 2>&1 && selene src || echo "WARN: selene не найден"
command -v stylua >/dev/null 2>&1 && stylua --check src || echo "WARN: stylua не найден"
command -v rojo >/dev/null 2>&1 && rojo build --output game.rbxlx || { echo "ERROR: rojo build упал"; exit 1; }

echo "==> [4/4] Smoke test"
# Юнит-тесты TestEZ гоняются в реальном движке через Open Cloud Luau Execution (см. docs/05).
# End-to-end петлю проверяет агент через Studio MCP (спавн->батарейка->генератор->Bear->выживание).
echo "Build OK. Прогони TestEZ через Open Cloud и сделай end-to-end плейтест в Studio MCP перед новой фичей."

echo "==> init.sh завершён."
