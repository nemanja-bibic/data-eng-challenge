-- Datamart: aggregated, dashboard-facing tables built by dbt on top of the
-- raw PeerDB mirror in `analytics`. dbt owns the tables; we own the database,
-- so it exists (and can be granted on) before the first `dbt build`.

CREATE DATABASE IF NOT EXISTS datamart;
