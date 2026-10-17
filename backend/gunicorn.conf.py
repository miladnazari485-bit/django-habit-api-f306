"""Conservative Gunicorn defaults that can be tuned through environment values."""

import multiprocessing
import os

bind = os.getenv("GUNICORN_BIND", "0.0.0.0:8000")
workers = int(
    os.getenv("GUNICORN_WORKERS", str(min((multiprocessing.cpu_count() * 2) + 1, 4)))
)
worker_class = "gthread"
threads = int(os.getenv("GUNICORN_THREADS", "2"))
timeout = int(os.getenv("GUNICORN_TIMEOUT", "30"))
graceful_timeout = int(os.getenv("GUNICORN_GRACEFUL_TIMEOUT", "30"))
keepalive = 5
max_requests = 1000
max_requests_jitter = 100
accesslog = "-"
errorlog = "-"
capture_output = True
forwarded_allow_ips = os.getenv("GUNICORN_FORWARDED_ALLOW_IPS", "127.0.0.1")
