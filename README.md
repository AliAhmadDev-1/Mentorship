# mentorship

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Seed test data

Use the API seeder to create representative testing data in the backend
database through the app endpoints:

```sh
dart run tool/seed_test_data.dart
```

To target another backend:

```sh
API_BASE_URL=http://localhost:8000/api dart run tool/seed_test_data.dart
```

Use `--suffix stable-name` when you want predictable test account emails.
