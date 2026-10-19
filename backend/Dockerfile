# syntax=docker/dockerfile:1

# Build dependency wheels once so the runtime image stays minimal.
FROM python:3.12-slim AS builder

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /build
COPY requirements.txt .
RUN python -m pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# Run the API as an unprivileged user in the final image.
FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DJANGO_ENV=production

RUN groupadd --system django \
    && useradd --system --gid django --create-home django

WORKDIR /app
COPY --from=builder /wheels /wheels
COPY requirements.txt .
RUN python -m pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt \
    && rm -rf /wheels

COPY --chown=django:django . .
RUN chmod 0555 /app/entrypoint.sh \
    && DJANGO_ENV=development DJANGO_SECRET_KEY=build-only \
       python manage.py collectstatic --noinput

USER django
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/live/', timeout=3)"]

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["gunicorn", "--config", "gunicorn.conf.py", "config.wsgi:application"]
