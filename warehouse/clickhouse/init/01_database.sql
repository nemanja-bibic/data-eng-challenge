-- The warehouse database. Created on first boot so the PeerDB destination
-- peer has somewhere to land.
--
-- The raw landing tables are deliberately NOT defined here: PeerDB owns the
-- destination DDL. It creates one ReplacingMergeTree per mirrored source
-- table, ordered by the source primary key and versioned by _peerdb_version,
-- and adds _peerdb_synced_at and _peerdb_is_deleted. Defining them by hand
-- would mean two owners of the same schema and a drift bug waiting to happen.
--
-- Modelled layers built on top of the raw mirror belong in later files here
-- (02_dims.sql, 03_facts.sql, ...), since those are ours to own.

CREATE DATABASE IF NOT EXISTS analytics;
