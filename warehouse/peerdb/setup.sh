#!/bin/sh
# Provisions the CDC pipeline end to end. Idempotent: re-running it is safe.
#
#   1. publication on the source Postgres (skipped if it already exists)
#   2. source + destination peers
#   3. the CDC mirror itself
#
# Run via `make mirror` once `docker compose up` reports everything healthy.
set -e

cd "$(dirname "$0")/../.."

echo "==> [1/3] postgres publication"
docker compose exec -T postgres psql -U postgres -d postgres \
  -c "DO \$\$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'peerdb_publication') THEN
          CREATE PUBLICATION peerdb_publication FOR TABLE
            public.users, public.models, public.assistants, public.conversations,
            public.messages, public.\"usage\", public.feedback;
        END IF;
      END \$\$;"

echo "==> [2/3] peers + [3/3] mirror"
docker compose exec -T postgres psql "host=peerdb port=9900 user=peerdb password=peerdb" \
  -v ON_ERROR_STOP=1 -f - < warehouse/peerdb/mirror.sql

echo "==> done. Watch progress at http://localhost:3000"
