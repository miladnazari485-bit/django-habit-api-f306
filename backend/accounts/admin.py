"""Administrative views for support staff."""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from accounts.forms import UserChangeForm, UserCreationForm
from accounts.models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    """Manage account state without displaying password material."""

    add_form = UserCreationForm
    form = UserChangeForm
    ordering = ("email",)
    list_display = ("email", "full_name", "is_active", "is_staff", "date_joined")
    search_fields = ("email", "full_name")
    readonly_fields = ("date_joined", "updated_at", "last_login")
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Profile", {"fields": ("full_name", "timezone")}),
        (
            "Permissions",
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        ("Dates", {"fields": ("last_login", "date_joined", "updated_at")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "password1", "password2", "is_staff"),
            },
        ),
    )
