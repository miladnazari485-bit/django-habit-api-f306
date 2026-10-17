"""Consistent, client-friendly API error responses."""

from rest_framework.views import exception_handler


def api_exception_handler(exc, context):
    """Wrap handled REST errors with a stable code and request identifier."""
    response = exception_handler(exc, context)
    if response is None:
        return None

    request = context.get("request")
    request_id = getattr(request, "request_id", None)
    details = response.data
    code = getattr(exc, "default_code", "error")

    response.data = {
        "error": {
            "code": code,
            "details": details,
            "requestId": request_id,
        }
    }
    return response
