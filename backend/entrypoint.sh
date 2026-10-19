#!/bin/sh
set -eu

# A single application replica may run migrations during simple deployments.
if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
    python manage.py migrate --noinput
fi

# Replace the shell so Gunicorn receives container stop signals directly.
exec "$@"
