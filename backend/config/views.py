"""Operational endpoints used by container and load-balancer health checks."""

from django.db import connection
from drf_spectacular.utils import extend_schema
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView


class LiveView(APIView):
    """Report whether the web process can serve HTTP."""

    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_classes = []

    @extend_schema(exclude=True)
    def get(self, request):
        """Return a minimal liveness result without exposing configuration."""
        return Response({"status": "ok"})


class ReadyView(APIView):
    """Report whether the process can reach its configured database."""

    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_classes = []

    @extend_schema(exclude=True)
    def get(self, request):
        """Run the smallest portable database readiness query."""
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        return Response({"status": "ready"})
