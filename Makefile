.PHONY: up down reseed logs ps psql clickhouse ch-schema mirror peerdb mirror-lag dbt dbt-debug dbt-build dbt-freshness

# Start everything (build images, run in background).
up:
	docker compose up --build -d

# Stop and remove containers AND the data volume (full reset).
down:
	docker compose down -v

# Wipe and reload the dataset in-place (keeps the volume/container).
reseed:
	docker compose run --rm seed python -m src.seed --force

# Follow logs from all services.
logs:
	docker compose logs -f

# Show service status.
ps:
	docker compose ps

# Open a psql shell against the running database.
psql:
	docker compose exec postgres psql -U postgres -d postgres

# Open a clickhouse-client shell against the warehouse.
clickhouse:
	docker compose exec clickhouse clickhouse-client --user analytics --password secret --database analytics

# Re-apply the warehouse DDL (the init dir only runs on an empty volume).
ch-schema:
	docker compose exec -T clickhouse clickhouse-client --user analytics --password secret --multiquery < warehouse/clickhouse/init/01_raw.sql

# Provision the Postgres -> ClickHouse CDC pipeline (publication, peers, mirror).
mirror:
	./warehouse/peerdb/setup.sh

# psql shell against the PeerDB server, for CREATE/DROP MIRROR and status queries.
peerdb:
	docker compose exec peerdb psql "host=localhost port=9900 user=peerdb password=peerdb"

# Row counts on both sides of the pipeline, to eyeball replication lag.
mirror-lag:
	@docker compose exec -T postgres psql -U postgres -d postgres -t -c \
	  "SELECT 'postgres.messages', count(*) FROM messages;"
	@docker compose exec -T clickhouse clickhouse-client --user analytics --password secret --query \
	  "SELECT 'clickhouse.raw_messages', count() FROM analytics.raw_messages"

# Shell inside the dbt container (project mounted at /usr/app).
dbt:
	docker compose exec dbt bash

# Check dbt can reach ClickHouse.
dbt-debug:
	docker compose exec dbt dbt debug

# Run and test all models.
dbt-build:
	docker compose exec dbt dbt build

# Fail if the mirror has stopped delivering messages/usage.
dbt-freshness:
	docker compose exec dbt dbt source freshness
