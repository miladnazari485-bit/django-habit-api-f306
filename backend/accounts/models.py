"""Authentication models for API users."""

import uuid

from django.contrib.auth.base_user import BaseUserManager
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models


class UserManager(BaseUserManager):
    """Create users with a normalized, case-insensitive email identity."""

    use_in_migrations = True

    def _create_user(self, email: str, password: str | None, **extra_fields):
        """Build and persist a user after validating required credentials."""
        if not email:
            raise ValueError("An email address is required.")
        email = self.normalize_email(email).casefold()
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email: str, password: str | None = None, **extra_fields):
        """Create a standard account without privileged flags."""
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email: str, password: str | None = None, **extra_fields):
        """Create an administrative account and enforce both privilege flags."""
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        if extra_fields.get("is_staff") is not True:
            raise ValueError("A superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("A superuser must have is_superuser=True.")
        return self._create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    """A UUID-based account that authenticates with email instead of username."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, max_length=254)
    full_name = models.CharField(max_length=150, blank=True)
    timezone = models.CharField(max_length=64, default="UTC")
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS: list[str] = []

    class Meta:
        ordering = ("email",)

    def save(self, *args, **kwargs):
        """Keep email uniqueness consistent across application code paths."""
        self.email = self.__class__.objects.normalize_email(self.email).casefold()
        super().save(*args, **kwargs)

    def __str__(self) -> str:
        """Represent users safely without exposing internal identifiers."""
        return self.email
