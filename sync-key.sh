#!/usr/bin/env bash
#
# Publish saber96's current IndexNow key file on this GitHub Pages site.
#
# Run after "Turn off" -> "Activate IndexNow" in the app: activating issues a
# NEW key, and the app only shows Active once https://saberms1.github.io/<key>.txt
# serves it. Reads the key from the local docker DB, replaces the old key
# file, commits and pushes. Pages takes ~1 minute to go live; then press
# "Check again" in the app.
#
set -euo pipefail
cd "$(dirname "$0")"

SHOP_ID="${1:-5}" # saber96
DOCKER_DIR="../infin-seo-dokcer-production"

KEY=$(cd "$DOCKER_DIR" && docker compose exec -T app php artisan tinker \
  --execute="echo optional(App\Models\IndexNowKey::where('shop_id', $SHOP_ID)->first())->key;" 2>/dev/null \
  | tr -d '[:space:]')

if ! [[ "$KEY" =~ ^[a-f0-9]{8,128}$ ]]; then
  echo "No IndexNow key for shop $SHOP_ID — press \"Activate IndexNow\" in the app first." >&2
  exit 1
fi

if [ -f "$KEY.txt" ]; then
  echo "Already published: https://saberms1.github.io/$KEY.txt"
  exit 0
fi

# Old key files are 32-hex-char names; nothing else here matches.
find . -maxdepth 1 -regex './[a-f0-9]\{8,128\}\.txt' -delete
printf '%s' "$KEY" > "$KEY.txt"

git add -A
git commit -qm "IndexNow key $KEY"
git push -q origin HEAD

echo "Pushed. In ~1 minute https://saberms1.github.io/$KEY.txt goes live — then press \"Check again\"."
