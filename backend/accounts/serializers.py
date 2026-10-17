"""Validation and representation for authentication endpoints."""

from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import IntegrityError
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken, TokenError

from accounts.models import User


def validate_timezone(value: str) -> str:
    """Accept only IANA timezone names understood by the Python runtime."""
    try:
        ZoneInfo(value)
    except ZoneInfoNotFoundError as exc:
        raise serializers.ValidationError("Enter a valid IANA timezone.") from exc
    return value


class UserSerializer(serializers.ModelSerializer):
    """Expose only account fields that clients may safely read or update."""

    fullName = serializers.CharField(source="full_name", required=False)
    dateJoined = serializers.DateTimeField(source="date_joined", read_only=True)

    class Meta:
        model = User
        fields = ("id", "email", "fullName", "timezone", "dateJoined")
        read_only_fields = ("id", "email", "dateJoined")

    def validate_timezone(self, value: str) -> str:
        """Validate profile timezone changes."""
        return validate_timezone(value)


class RegisterSerializer(serializers.ModelSerializer):
    """Create a non-privileged user after Django password validation."""

    password = serializers.CharField(write_only=True, trim_whitespace=False)
    fullName = serializers.CharField(
        source="full_name", required=False, allow_blank=True
    )

    class Meta:
        model = User
        fields = ("id", "email", "password", "fullName", "timezone")
        read_only_fields = ("id",)

    def validate_email(self, value: str) -> str:
        """Normalize case and return one generic duplicate-account message."""
        email = User.objects.normalize_email(value).casefold()
        if User.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError("An account with this email exists.")
        return email

    def validate_timezone(self, value: str) -> str:
        """Validate the optional registration timezone."""
        return validate_timezone(value)

    def validate(self, attrs):
        """Run configured password rules against the proposed identity."""
        candidate = User(
            email=attrs.get("email", ""),
            full_name=attrs.get("full_name", ""),
        )
        try:
            validate_password(attrs["password"], user=candidate)
        except DjangoValidationError as exc:
            raise serializers.ValidationError({"password": exc.messages}) from exc
        return attrs

    def create(self, validated_data):
        """Delegate password hashing and safe defaults to the user manager."""
        try:
            return User.objects.create_user(**validated_data)
        except IntegrityError as exc:
            raise serializers.ValidationError(
                {"email": "An account with this email exists."}
            ) from exc


class LoginSerializer(TokenObtainPairSerializer):
    """Issue a JWT pair and include the authenticated public profile."""

    def validate(self, attrs):
        """Authenticate credentials before adding client bootstrap data."""
        attrs[self.username_field] = User.objects.normalize_email(
            attrs[self.username_field]
        ).casefold()
        data = super().validate(attrs)
        data["user"] = UserSerializer(self.user).data
        return data


class LogoutSerializer(serializers.Serializer):
    """Blacklist a refresh token so it cannot mint another access token."""

    refresh = serializers.CharField(write_only=True)

    def save(self, **kwargs):
        """Blacklist only a refresh token owned by the current user."""
        try:
            token = RefreshToken(self.validated_data["refresh"])
            user = self.context["request"].user
            if str(token["user_id"]) != str(user.pk):
                raise serializers.ValidationError(
                    {"refresh": "The refresh token is invalid or expired."}
                )
            token.blacklist()
        except TokenError as exc:
            raise serializers.ValidationError(
                {"refresh": "The refresh token is invalid or expired."}
            ) from exc
