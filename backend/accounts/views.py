"""Authentication and current-user API actions."""

from drf_spectacular.utils import extend_schema
from rest_framework import generics, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle, ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenVerifyView,
)

from accounts.serializers import (
    LoginSerializer,
    LogoutSerializer,
    RegisterSerializer,
    UserSerializer,
)


class RegisterView(generics.CreateAPIView):
    """Create a standard user account."""

    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = RegisterSerializer
    throttle_classes = [AnonRateThrottle, ScopedRateThrottle]
    throttle_scope = "register"


class LoginView(TokenObtainPairView):
    """Exchange email and password for a short-lived JWT pair."""

    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = LoginSerializer
    throttle_classes = [AnonRateThrottle, ScopedRateThrottle]
    throttle_scope = "login"


class RefreshView(TokenRefreshView):
    """Rotate a valid refresh token and blacklist the previous token."""

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [AnonRateThrottle, ScopedRateThrottle]
    throttle_scope = "login"


class VerifyView(TokenVerifyView):
    """Check token integrity without returning account information."""

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [AnonRateThrottle, ScopedRateThrottle]
    throttle_scope = "login"


class LogoutView(APIView):
    """Invalidate the supplied refresh token for the authenticated user."""

    @extend_schema(
        request=LogoutSerializer,
        responses={204: None},
    )
    def post(self, request):
        """Validate and blacklist one refresh token."""
        serializer = LogoutSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(status=status.HTTP_204_NO_CONTENT)


class MeView(generics.RetrieveUpdateAPIView):
    """Read or partially update the authenticated user's profile."""

    serializer_class = UserSerializer
    http_method_names = ["get", "patch", "head", "options"]

    def get_object(self):
        """Return the identity resolved by JWT authentication."""
        return self.request.user
