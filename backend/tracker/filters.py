"""Explicit query filters for predictable mobile and web requests."""

import django_filters

from tracker.models import Habit, HabitEntry, Task
from tracker.serializers import user_today


class HabitFilter(django_filters.FilterSet):
    """Filter habits by their type and archive state."""

    class Meta:
        model = Habit
        fields = ("kind", "archived")


class HabitEntryFilter(django_filters.FilterSet):
    """Filter daily entries by habit and an inclusive date range."""

    habitId = django_filters.UUIDFilter(field_name="habit_id")
    dateFrom = django_filters.DateFilter(field_name="date", lookup_expr="gte")
    dateTo = django_filters.DateFilter(field_name="date", lookup_expr="lte")

    class Meta:
        model = HabitEntry
        fields = ("habitId", "date", "dateFrom", "dateTo")


class TaskFilter(django_filters.FilterSet):
    """Filter tasks by completion, due range, or overdue status."""

    dueFrom = django_filters.DateFilter(field_name="due_date", lookup_expr="gte")
    dueTo = django_filters.DateFilter(field_name="due_date", lookup_expr="lte")
    overdue = django_filters.BooleanFilter(method="filter_overdue")

    class Meta:
        model = Task
        fields = ("done", "dueFrom", "dueTo", "overdue")

    def filter_overdue(self, queryset, name, value):
        """Apply overdue semantics in the current user's local timezone."""
        if value is True:
            return queryset.filter(
                done=False,
                due_date__lt=user_today(self.request.user),
            )
        return queryset
