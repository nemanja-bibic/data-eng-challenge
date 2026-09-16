FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DBT_PROFILES_DIR=/usr/app

# git is needed by `dbt deps` for git-hosted packages.
RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# The project itself is bind-mounted here by docker-compose, so edits on the
# host are picked up without rebuilding the image.
WORKDIR /usr/app

# Stay up so commands can be run with `docker compose exec dbt dbt <cmd>`.
CMD ["tail", "-f", "/dev/null"]
