"""Small HTTP middleware shared by every API endpoint."""

from uuid import UUID, uuid4


class RequestIDMiddleware:
    """Attach a safe request identifier for tracing client and server errors."""

    header_name = "HTTP_X_REQUEST_ID"

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request.request_id = self._request_id(request.META.get(self.header_name))
        response = self.get_response(request)
        response["X-Request-ID"] = request.request_id
        return response

    @staticmethod
    def _request_id(candidate: str | None) -> str:
        """Accept UUID request IDs only, preventing untrusted log/header content."""
        if candidate:
            try:
                return str(UUID(candidate))
            except (ValueError, AttributeError):
                pass
        return str(uuid4())
