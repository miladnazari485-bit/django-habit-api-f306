"""Admin forms adapted to the email-based custom user model."""

from django.contrib.auth.forms import (
    UserChangeForm as DjangoUserChangeForm,
)
from django.contrib.auth.forms import (
    UserCreationForm as DjangoUserCreationForm,
)

from accounts.models import User


class UserCreationForm(DjangoUserCreationForm):
    """Create admin-managed users without a username field."""

    class Meta(DjangoUserCreationForm.Meta):
        model = User
        fields = ("email", "full_name", "timezone")


class UserChangeForm(DjangoUserChangeForm):
    """Edit the public and permission fields of an existing user."""

    class Meta(DjangoUserChangeForm.Meta):
        model = User
        fields = "__all__"
