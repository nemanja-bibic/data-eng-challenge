-- CDC pipeline: operational Postgres -> ClickHouse warehouse.
-- Applied by `make mirror`. Idempotent via IF NOT EXISTS.
--
-- Peers are addressed by their compose service names, so everything resolves
-- on the internal network; nothing here depends on host ports.

CREATE PEER IF NOT EXISTS pg_source FROM POSTGRES WITH (
  host     = 'postgres',
  port     = '5432',
  user     = 'postgres',
  password = 'secret',
  database = 'postgres'
);

-- Port 9000 is the ClickHouse *native* protocol; PeerDB does not use 8123.
CREATE PEER IF NOT EXISTS ch_warehouse FROM CLICKHOUSE WITH (
  host     = 'clickhouse',
  port     = 9000,
  user     = 'analytics',
  password = 'secret',
  database = 'analytics',
  -- Local ClickHouse listens plaintext on the native port; PeerDB assumes TLS.
  disable_tls = true
);

-- Target names are unqualified: ClickHouse mirrors take the table name only,
-- resolved against the peer's database. The raw_ prefix keeps the landing
-- layer visually distinct from modelled tables built on top of it.
CREATE MIRROR IF NOT EXISTS pg_to_ch
FROM pg_source TO ch_warehouse
WITH TABLE MAPPING (
  public.users:raw_users,
  public.models:raw_models,
  public.assistants:raw_assistants,
  public.conversations:raw_conversations,
  public.messages:raw_messages,
  public.usage:raw_usage,
  public.feedback:raw_feedback
)
WITH (
  do_initial_copy = true,
  publication_name = 'peerdb_publication',
  replication_slot_name = 'peerdb_slot',
  sync_interval = 30,
  snapshot_num_rows_per_partition = 50000,
  snapshot_max_parallel_workers = 4,
  snapshot_num_tables_in_parallel = 2
);
