"""Authentication API regression tests."""

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import User


class AuthenticationAPITests(APITestCase):
    """Exercise registration, JWT issue, profile, and token revocation."""

    password = "Long-Unique-Passphrase-2048!"

    def test_register_normalizes_email_and_hashes_password(self):
        """Registration must never persist or return raw password material."""
        response = self.client.post(
            reverse("register"),
            {
                "email": "New.User@Example.COM",
                "password": self.password,
                "fullName": "New User",
                "timezone": "Europe/Amsterdam",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertNotIn("password", response.data)
        user = User.objects.get()
        self.assertEqual(user.email, "new.user@example.com")
        self.assertTrue(user.check_password(self.password))

    def test_login_profile_and_logout_flow(self):
        """A refresh token works before logout and is rejected afterward."""
        user = User.objects.create_user(
            email="owner@example.com",
            password=self.password,
            full_name="Owner",
        )
        login = self.client.post(
            reverse("login"),
            {"email": user.email.upper(), "password": self.password},
            format="json",
        )

        self.assertEqual(login.status_code, status.HTTP_200_OK)
        self.assertEqual(login.data["user"]["email"], user.email)
        access = login.data["access"]
        refresh = login.data["refresh"]

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
        profile = self.client.patch(
            reverse("me"),
            {"fullName": "Updated Owner", "timezone": "Asia/Tehran"},
            format="json",
        )
        self.assertEqual(profile.status_code, status.HTTP_200_OK)
        self.assertEqual(profile.data["fullName"], "Updated Owner")

        logout = self.client.post(
            reverse("logout"),
            {"refresh": refresh},
            format="json",
        )
        self.assertEqual(logout.status_code, status.HTTP_204_NO_CONTENT)

        self.client.credentials()
        rejected = self.client.post(
            reverse("token-refresh"),
            {"refresh": refresh},
            format="json",
        )
        self.assertEqual(rejected.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_invalid_timezone_is_rejected(self):
        """Profiles store only timezone names that date logic can load."""
        response = self.client.post(
            reverse("register"),
            {
                "email": "zone@example.com",
                "password": self.password,
                "timezone": "Mars/Olympus",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_weak_password_is_returned_as_a_validation_error(self):
        """Django password rules must produce a safe client error, not a 500."""
        response = self.client.post(
            reverse("register"),
            {
                "email": "weak@example.com",
                "password": "password",
                "timezone": "UTC",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("password", response.data["error"]["details"])
