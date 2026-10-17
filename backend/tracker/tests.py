"""Tracker API behavior and authorization tests."""

from datetime import timedelta

from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import User
from tracker.models import Habit, HabitEntry, Task


class TrackerAPITests(APITestCase):
    """Verify CRUD behavior and strict per-user data isolation."""

    def setUp(self):
        """Create two users and authenticate the primary API client."""
        self.owner = User.objects.create_user(
            email="owner@example.com",
            password="Long-Unique-Passphrase-2048!",
        )
        self.other = User.objects.create_user(
            email="other@example.com",
            password="Long-Unique-Passphrase-4096!",
        )
        self.client.force_authenticate(self.owner)

    def create_habit(self, owner=None, **overrides):
        """Build one valid habit for focused API tests."""
        values = {
            "owner": owner or self.owner,
            "name": "Drink Water",
            "kind": Habit.Kind.COUNT,
            "goal": 8,
            "unit": "glass",
        }
        values.update(overrides)
        return Habit.objects.create(**values)

    def test_habit_crud_never_exposes_another_users_data(self):
        """List and detail operations must apply ownership before lookup."""
        own_habit = self.create_habit()
        other_habit = self.create_habit(owner=self.other, name="Private")

        listing = self.client.get(reverse("habit-list"))
        self.assertEqual(listing.status_code, status.HTTP_200_OK)
        self.assertEqual(listing.data["count"], 1)
        self.assertEqual(listing.data["results"][0]["id"], str(own_habit.id))

        hidden = self.client.get(reverse("habit-detail", args=(other_habit.id,)))
        self.assertEqual(hidden.status_code, status.HTTP_404_NOT_FOUND)

    def test_record_action_upserts_and_zero_deletes_daily_value(self):
        """The mobile-friendly record action has one row per habit and date."""
        habit = self.create_habit()
        today = timezone.localdate()
        url = reverse("habit-record", args=(habit.id,))

        created = self.client.post(
            url,
            {"date": today.isoformat(), "value": 3},
            format="json",
        )
        self.assertEqual(created.status_code, status.HTTP_200_OK)
        self.assertEqual(HabitEntry.objects.get().value, 3)

        updated = self.client.post(
            url,
            {"date": today.isoformat(), "value": 5},
            format="json",
        )
        self.assertEqual(updated.status_code, status.HTTP_200_OK)
        self.assertEqual(HabitEntry.objects.get().value, 5)
        self.assertEqual(HabitEntry.objects.count(), 1)

        deleted = self.client.post(
            url,
            {"date": today.isoformat(), "value": 0},
            format="json",
        )
        self.assertEqual(deleted.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(HabitEntry.objects.exists())

    def test_future_entry_and_foreign_habit_are_rejected(self):
        """Clients cannot forge future progress or another user's ownership."""
        own_habit = self.create_habit()
        other_habit = self.create_habit(owner=self.other, name="Private")
        future = timezone.localdate() + timedelta(days=1)

        future_response = self.client.post(
            reverse("habit-record", args=(own_habit.id,)),
            {"date": future.isoformat(), "value": 1},
            format="json",
        )
        self.assertEqual(future_response.status_code, status.HTTP_400_BAD_REQUEST)

        foreign_response = self.client.post(
            reverse("habit-entry-list"),
            {
                "habitId": str(other_habit.id),
                "date": timezone.localdate().isoformat(),
                "value": 1,
            },
            format="json",
        )
        self.assertEqual(foreign_response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_task_done_transitions_maintain_completed_timestamp(self):
        """Completion metadata follows done state changes."""
        created = self.client.post(
            reverse("task-list"),
            {
                "title": "Buy groceries",
                "dueDate": timezone.localdate().isoformat(),
                "done": False,
            },
            format="json",
        )
        self.assertEqual(created.status_code, status.HTTP_201_CREATED)
        task = Task.objects.get()
        self.assertIsNone(task.completed_at)

        completed = self.client.patch(
            reverse("task-detail", args=(task.id,)),
            {"done": True},
            format="json",
        )
        self.assertEqual(completed.status_code, status.HTTP_200_OK)
        task.refresh_from_db()
        self.assertIsNotNone(task.completed_at)

        reopened = self.client.patch(
            reverse("task-detail", args=(task.id,)),
            {"done": False},
            format="json",
        )
        self.assertEqual(reopened.status_code, status.HTTP_200_OK)
        task.refresh_from_db()
        self.assertIsNone(task.completed_at)

    def test_dashboard_combines_today_habits_and_tasks(self):
        """The dashboard returns the minimum bootstrap payload for Today."""
        habit = self.create_habit(goal=2)
        today = timezone.localdate()
        HabitEntry.objects.create(habit=habit, date=today, value=2)
        Task.objects.create(owner=self.owner, title="Today", due_date=today)

        response = self.client.get(
            reverse("dashboard"),
            {"date": today.isoformat()},
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["completedHabits"], 1)
        self.assertEqual(response.data["habits"][0]["value"], 2)
        self.assertEqual(len(response.data["tasks"]), 1)
