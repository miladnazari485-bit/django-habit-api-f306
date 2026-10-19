"""Persistent habit, daily-entry, and one-off task models."""

import uuid

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.db.models import Q


class TimeStampedUUIDModel(models.Model):
    """Provide stable public identifiers and audit timestamps."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class Habit(TimeStampedUUIDModel):
    """A repeating check or count goal owned by exactly one user."""

    class Kind(models.TextChoices):
        CHECK = "check", "Check"
        COUNT = "count", "Count"

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="habits",
    )
    name = models.CharField(max_length=120)
    color = models.PositiveBigIntegerField(
        default=0xFF6750A4,
        validators=[MinValueValidator(0), MaxValueValidator(0xFFFFFFFF)],
    )
    kind = models.CharField(max_length=10, choices=Kind.choices, default=Kind.CHECK)
    goal = models.PositiveIntegerField(
        default=1,
        validators=[MinValueValidator(1), MaxValueValidator(1_000_000)],
    )
    unit = models.CharField(max_length=32, default="time")
    archived = models.BooleanField(default=False)

    class Meta:
        ordering = ("created_at", "id")
        indexes = [
            models.Index(
                fields=("owner", "archived", "created_at"),
                name="habit_owner_state_idx",
            )
        ]
        constraints = [
            models.CheckConstraint(
                condition=Q(goal__gte=1),
                name="habit_goal_positive",
            )
        ]

    def __str__(self) -> str:
        """Show the habit name in logs and administration."""
        return self.name


class HabitEntry(TimeStampedUUIDModel):
    """The positive value recorded for one habit on one calendar date."""

    habit = models.ForeignKey(
        Habit,
        on_delete=models.CASCADE,
        related_name="entries",
    )
    date = models.DateField()
    value = models.PositiveIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(2_147_483_647)]
    )

    class Meta:
        ordering = ("-date", "-created_at")
        constraints = [
            models.UniqueConstraint(
                fields=("habit", "date"),
                name="unique_habit_entry_date",
            ),
            models.CheckConstraint(
                condition=Q(value__gte=1),
                name="habit_entry_value_positive",
            ),
        ]
        indexes = [models.Index(fields=("habit", "date"), name="entry_habit_date_idx")]

    def __str__(self) -> str:
        """Show a concise entry label in administration."""
        return f"{self.habit.name}: {self.date} = {self.value}"


class Task(TimeStampedUUIDModel):
    """A one-off user task with a due date and completion state."""

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="tasks",
    )
    title = models.CharField(max_length=240)
    due_date = models.DateField()
    done = models.BooleanField(default=False)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("done", "due_date", "created_at")
        indexes = [
            models.Index(
                fields=("owner", "done", "due_date"),
                name="task_owner_due_idx",
            )
        ]

    def __str__(self) -> str:
        """Show the task title in logs and administration."""
        return self.title
