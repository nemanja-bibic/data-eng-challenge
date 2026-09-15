-- Postgres-side CDC prerequisite, applied before the mirror is created.
--
-- Naming the publication explicitly (rather than letting PeerDB create one)
-- keeps the replicated table set under version control: adding a table to the
-- warehouse is a visible change here, not a side effect of a UI click.
--
-- wal_level=logical and the replication slot budget are already set by the
-- postgres service command in docker-compose.yml. Every table below has a
-- primary key, which logical replication requires for UPDATE/DELETE.

CREATE PUBLICATION peerdb_publication FOR TABLE
    public.users,
    public.models,
    public.assistants,
    public.conversations,
    public.messages,
    public."usage",
    public.feedback;
