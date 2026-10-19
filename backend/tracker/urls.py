"""Version-one tracker resource routes."""

from django.urls import include, path
from rest_framework.routers import DefaultRouter

from tracker.views import DashboardView, HabitEntryViewSet, HabitViewSet, TaskViewSet

router = DefaultRouter()
router.register("habits", HabitViewSet, basename="habit")
router.register("habit-entries", HabitEntryViewSet, basename="habit-entry")
router.register("tasks", TaskViewSet, basename="task")

urlpatterns = [
    path("", include(router.urls)),
    path("dashboard/", DashboardView.as_view(), name="dashboard"),
]
