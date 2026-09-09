#!/usr/bin/env bash
set -euo pipefail

WEB_DIR="/var/www/html/<WEBROOT>"
DATA_FILE="${WEB_DIR}/data/cards.json"
STATUS_FILE="${WEB_DIR}/data/status.json"

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

results_file="$(mktemp)"
trap 'rm -f "${results_file}"' EXIT

while IFS=$'\t' read -r card_id card_url card_user card_pass; do
  if [[ -z "${card_id}" || -z "${card_url}" ]]; then
    continue
  fi

  curl_args=(
    -sS
    -L
    --max-time 20
    --connect-timeout 10
    -o /dev/null
    -w '%{http_code}'
  )

  if [[ -n "${card_user:-}" || -n "${card_pass:-}" ]]; then
    curl_args+=( -u "${card_user:-}:${card_pass:-}" )
  fi

  http_code="$(curl "${curl_args[@]}" "${card_url}" || true)"

  if [[ "${http_code}" == "200" ]]; then
    status="live"
    status_label="Available"
  elif [[ "${http_code}" == "401" ]]; then
    status="offline"
    status_label="Auth Required"
  else
    status="offline"
    status_label="Offline"
  fi

  printf '%s\t%s\t%s\t%s\n' "${card_id}" "${status}" "${status_label}" "${http_code}" >> "${results_file}"
done < <(
  python3 - "${DATA_FILE}" <<'PY'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
  cards = json.load(f)

for group in ('demos', 'tools'):
  for section in cards.get(group, {}).get('sections', []):
    for card in section.get('cards', []):
      card_id = card.get('id', '').strip()
      link = card.get('link', '').strip()
      auth = card.get('auth') or {}
      card_user = auth.get('user', '') if isinstance(auth, dict) else ''
      card_pass = auth.get('pass', '') if isinstance(auth, dict) else ''
      if card_id and link:
        print(f"{card_id}\t{link}\t{card_user}\t{card_pass}")
PY
)

python3 - "${DATA_FILE}" "${results_file}" "${STATUS_FILE}" <<'PY'
import datetime
import json
import sys

data_file = sys.argv[1]
results_file = sys.argv[2]
status_file = sys.argv[3]

with open(data_file, 'r', encoding='utf-8') as f:
    cards = json.load(f)

links_by_id = {}
for group in ('demos', 'tools'):
    for section in cards.get(group, {}).get('sections', []):
        for card in section.get('cards', []):
            card_id = card.get('id', '').strip()
            link = card.get('link', '').strip()
            if card_id:
                links_by_id[card_id] = link

items = {}
with open(results_file, 'r', encoding='utf-8') as f:
    for line in f:
        card_id, status, status_label, http_code = line.rstrip('\n').split('\t')
        items[card_id] = {
            'status': status,
            'statusLabel': status_label,
            'httpCode': int(http_code) if http_code.isdigit() else 0,
            'url': links_by_id.get(card_id, '')
        }

payload = {
    'checkedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'items': items
}

tmp_path = f"{status_file}.tmp"
with open(tmp_path, 'w', encoding='utf-8') as f:
    json.dump(payload, f, indent=2)
    f.write('\n')

import os
os.replace(tmp_path, status_file)
PY

echo "Status updated at ${STATUS_FILE}"
