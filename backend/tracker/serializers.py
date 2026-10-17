"""REST representations and validation for tracker resources."""

from datetime import date, datetime
from zoneinfo import ZoneInfo

from django.db import transaction
from django.utils import timezone
from rest_framework import serializers

from tracker.models import Habit, HabitEntry, Task


def user_today(user) -> date:
    """Resolve today's date in the authenticated user's preferred timezone."""
    return datetime.now(ZoneInfo(user.timezone)).date()


class HabitSerializer(serializers.ModelSerializer):
    """Represent habit settings with names matching Flutter and JavaScript."""

    createdAt = serializers.DateTimeField(source="created_at", read_only=True)
    updatedAt = serializers.DateTimeField(source="updated_at", read_only=True)

    class Meta:
        model = Habit
        fields = (
            "id",
            "name",
            "color",
            "kind",
            "goal",
            "unit",
            "archived",
            "createdAt",
            "updatedAt",
        )
        read_only_fields = ("id", "createdAt", "updatedAt")

    def validate_name(self, value: str) -> str:
        """Reject names that become empty after trimming."""
        value = value.strip()
        if not value:
            raise serializers.ValidationError("The habit name cannot be empty.")
        return value

    def validate_unit(self, value: str) -> str:
        """Store a compact non-empty unit label."""
        value = value.strip()
        if not value:
            raise serializers.ValidationError("The unit cannot be empty.")
        return value

    def validate(self, attrs):
        """Keep once-a-day check habits at a goal of exactly one."""
        kind = attrs.get("kind", getattr(self.instance, "kind", Habit.Kind.CHECK))
        goal = attrs.get("goal", getattr(self.instance, "goal", 1))
        if kind == Habit.Kind.CHECK and goal != 1:
            raise serializers.ValidationError(
                {"goal": "Check habits must use a goal of 1."}
            )
        return attrs


class DashboardHabitSerializer(HabitSerializer):
    """Add one day's progress to the reusable habit representation."""

    value = serializers.IntegerField(read_only=True)
    completed = serializers.BooleanField(read_only=True)

    class Meta(HabitSerializer.Meta):
        fields = (*HabitSerializer.Meta.fields, "value", "completed")


class HabitEntrySerializer(serializers.ModelSerializer):
    """Represent one daily value while enforcing owner isolation."""

    habitId = serializers.PrimaryKeyRelatedField(
        source="habit",
        queryset=Habit.objects.none(),
    )
    createdAt = serializers.DateTimeField(source="created_at", read_only=True)
    updatedAt = serializers.DateTimeField(source="updated_at", read_only=True)

    class Meta:
        model = HabitEntry
        fields = ("id", "habitId", "date", "value", "createdAt", "updatedAt")
        read_only_fields = ("id", "createdAt", "updatedAt")

    def __init__(self, *args, **kwargs):
        """Limit writable habit IDs to the authenticated user's records."""
        super().__init__(*args, **kwargs)
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            self.fields["habitId"].queryset = Habit.objects.filter(owner=request.user)

    def validate_date(self, value):
        """Prevent future activity from changing current streaks."""
        if value > user_today(self.context["request"].user):
            raise serializers.ValidationError("Future habit entries are not allowed.")
        return value

    def validate(self, attrs):
        """Return a clear error before the unique database constraint runs."""
        habit = attrs.get("habit", getattr(self.instance, "habit", None))
        date = attrs.get("date", getattr(self.instance, "date", None))
        query = HabitEntry.objects.filter(habit=habit, date=date)
        if self.instance:
            query = query.exclude(pk=self.instance.pk)
        if query.exists():
            raise serializers.ValidationError(
                {"date": "This habit already has an entry for that date."}
            )
        return attrs


class RecordHabitSerializer(serializers.Serializer):
    """Validate the atomic upsert/delete action used by tracker clients."""

    date = serializers.DateField()
    value = serializers.IntegerField(min_value=0, max_value=2_147_483_647)

    def validate_date(self, value):
        """Prevent recording future activity."""
        if value > user_today(self.context["request"].user):
            raise serializers.ValidationError("Future habit entries are not allowed.")
        return value

    def save(self, **kwargs):
        """Set a daily value, or delete that day when the value is zero."""
        habit = self.context["habit"]
        date = self.validated_data["date"]
        value = self.validated_data["value"]

        if value == 0:
            HabitEntry.objects.filter(habit=habit, date=date).delete()
            return None

        with transaction.atomic():
            entry, _ = HabitEntry.objects.update_or_create(
                habit=habit,
                date=date,
                defaults={"value": value},
            )
        return entry


class TaskSerializer(serializers.ModelSerializer):
    """Represent one-off tasks and maintain their completion timestamp."""

    dueDate = serializers.DateField(source="due_date")
    completedAt = serializers.DateTimeField(source="completed_at", read_only=True)
    createdAt = serializers.DateTimeField(source="created_at", read_only=True)
    updatedAt = serializers.DateTimeField(source="updated_at", read_only=True)

    class Meta:
        model = Task
        fields = (
            "id",
            "title",
            "dueDate",
            "done",
            "completedAt",
            "createdAt",
            "updatedAt",
        )
        read_only_fields = ("id", "completedAt", "createdAt", "updatedAt")

    def validate_title(self, value: str) -> str:
        """Reject task titles that become empty after trimming."""
        value = value.strip()
        if not value:
            raise serializers.ValidationError("The task title cannot be empty.")
        return value

    def create(self, validated_data):
        """Set the completion time when a task is created as done."""
        if validated_data.get("done"):
            validated_data["completed_at"] = timezone.now()
        return super().create(validated_data)

    def update(self, instance, validated_data):
        """Update completion time only when the done state changes."""
        next_done = validated_data.get("done", instance.done)
        if next_done and not instance.done:
            validated_data["completed_at"] = timezone.now()
        elif not next_done and instance.done:
            validated_data["completed_at"] = None
        return super().update(instance, validated_data)
