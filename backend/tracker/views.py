"""Owner-scoped REST actions for the habit tracker domain."""

from django.db.models import Prefetch
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import serializers, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from tracker.filters import HabitEntryFilter, HabitFilter, TaskFilter
from tracker.models import Habit, HabitEntry, Task
from tracker.serializers import (
    DashboardHabitSerializer,
    HabitEntrySerializer,
    HabitSerializer,
    RecordHabitSerializer,
    TaskSerializer,
    user_today,
)


class OwnerQuerySetMixin:
    """Return an empty schema queryset or records owned by the current user."""

    owner_lookup = "owner"

    def scope_to_user(self, queryset):
        """Apply the configured ownership path to every database operation."""
        user = self.request.user
        if not user.is_authenticated:
            return queryset.none()
        return queryset.filter(**{self.owner_lookup: user})


class HabitViewSet(OwnerQuerySetMixin, viewsets.ModelViewSet):
    """Create, list, update, archive, or delete the user's habits."""

    serializer_class = HabitSerializer
    filterset_class = HabitFilter
    search_fields = ("name", "unit")
    ordering_fields = ("created_at", "updated_at", "name")
    ordering = ("created_at",)

    def get_queryset(self):
        """Scope every habit lookup to the JWT identity."""
        return self.scope_to_user(Habit.objects.all())

    def perform_create(self, serializer):
        """Set ownership from authentication instead of request data."""
        serializer.save(owner=self.request.user)

    @extend_schema(
        request=RecordHabitSerializer,
        responses={200: HabitEntrySerializer, 204: None},
    )
    @action(detail=True, methods=("post",), url_path="record")
    def record(self, request, pk=None):
        """Atomically set one day's value, deleting it when value is zero."""
        habit = self.get_object()
        serializer = RecordHabitSerializer(
            data=request.data,
            context={"request": request, "habit": habit},
        )
        serializer.is_valid(raise_exception=True)
        entry = serializer.save()
        if entry is None:
            return Response(status=status.HTTP_204_NO_CONTENT)
        return Response(
            HabitEntrySerializer(entry, context={"request": request}).data,
            status=status.HTTP_200_OK,
        )


class HabitEntryViewSet(OwnerQuerySetMixin, viewsets.ModelViewSet):
    """Expose standard CRUD for synchronization and date-range queries."""

    serializer_class = HabitEntrySerializer
    filterset_class = HabitEntryFilter
    ordering_fields = ("date", "created_at", "updated_at")
    ordering = ("-date",)
    owner_lookup = "habit__owner"

    def get_queryset(self):
        """Scope entries through their parent habit's owner."""
        return self.scope_to_user(HabitEntry.objects.select_related("habit"))


class TaskViewSet(OwnerQuerySetMixin, viewsets.ModelViewSet):
    """Create and manage the user's one-off tasks."""

    serializer_class = TaskSerializer
    filterset_class = TaskFilter
    search_fields = ("title",)
    ordering_fields = ("due_date", "created_at", "updated_at", "title")
    ordering = ("done", "due_date", "created_at")

    def get_queryset(self):
        """Scope every task lookup to the JWT identity."""
        return self.scope_to_user(Task.objects.all())

    def perform_create(self, serializer):
        """Set ownership from authentication instead of request data."""
        serializer.save(owner=self.request.user)


class DashboardView(APIView):
    """Return one request-sized snapshot for the Today screen."""

    @extend_schema(
        parameters=[
            inline_serializer(
                name="DashboardQuery",
                fields={"date": serializers.DateField(required=False)},
            )
        ],
        responses={
            200: inline_serializer(
                name="DashboardResponse",
                fields={
                    "date": serializers.DateField(),
                    "habits": DashboardHabitSerializer(many=True),
                    "tasks": TaskSerializer(many=True),
                    "overdueTaskCount": serializers.IntegerField(),
                    "completedHabits": serializers.IntegerField(),
                    "totalHabits": serializers.IntegerField(),
                },
            )
        },
    )
    def get(self, request):
        """Combine habit values and due tasks for a requested local date."""
        target_date = self._target_date(request)
        entries = HabitEntry.objects.filter(date=target_date)
        habits = (
            Habit.objects.filter(owner=request.user, archived=False)
            .prefetch_related(
                Prefetch("entries", queryset=entries, to_attr="day_entries")
            )
            .order_by("created_at")
        )

        habit_rows = []
        completed = 0
        for habit in habits:
            value = habit.day_entries[0].value if habit.day_entries else 0
            is_complete = value >= habit.goal
            completed += int(is_complete)
            habit.value = value
            habit.completed = is_complete
            habit_rows.append(DashboardHabitSerializer(habit).data)

        tasks = Task.objects.filter(owner=request.user, due_date=target_date)
        overdue_count = Task.objects.filter(
            owner=request.user,
            done=False,
            due_date__lt=user_today(request.user),
        ).count()

        return Response(
            {
                "date": target_date,
                "habits": habit_rows,
                "tasks": TaskSerializer(tasks, many=True).data,
                "overdueTaskCount": overdue_count,
                "completedHabits": completed,
                "totalHabits": len(habit_rows),
            }
        )

    @staticmethod
    def _target_date(request):
        """Parse the optional date or default to the user's current date."""
        raw_date = request.query_params.get("date")
        if not raw_date:
            return user_today(request.user)
        field = serializers.DateField()
        try:
            return field.run_validation(raw_date)
        except serializers.ValidationError as exc:
            raise ValidationError({"date": exc.detail}) from exc
