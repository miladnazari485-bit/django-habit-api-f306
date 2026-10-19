"""Read-friendly administration for tracker data."""

from django.contrib import admin

from tracker.models import Habit, HabitEntry, Task


@admin.register(Habit)
class HabitAdmin(admin.ModelAdmin):
    """Support habit lookup while preserving owner visibility."""

    list_display = ("name", "owner", "kind", "goal", "unit", "archived")
    list_filter = ("kind", "archived")
    search_fields = ("name", "owner__email")
    readonly_fields = ("id", "created_at", "updated_at")


@admin.register(HabitEntry)
class HabitEntryAdmin(admin.ModelAdmin):
    """Support date-based entry inspection."""

    list_display = ("habit", "date", "value", "updated_at")
    list_filter = ("date",)
    search_fields = ("habit__name", "habit__owner__email")
    readonly_fields = ("id", "created_at", "updated_at")


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    """Support task lookup by owner and state."""

    list_display = ("title", "owner", "due_date", "done", "completed_at")
    list_filter = ("done", "due_date")
    search_fields = ("title", "owner__email")
    readonly_fields = ("id", "created_at", "updated_at", "completed_at")
