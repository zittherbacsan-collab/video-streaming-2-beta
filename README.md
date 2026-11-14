# MIDWEEK MEETING SC9

A simple, single-organizer Flutter app for preparing the Cebuano **Eskedyul sa Midweek nga Tigom**. The app is local-first: it has no sign-in, accounts, member directory, roles, server, Supabase, Firebase, or notification service.

## Current features

- Create, edit, save, reopen, duplicate, and delete weekly schedules.
- Save schedules locally on the device/browser using `shared_preferences`.
- Edit the congregation name, date, weekly Bible reading, chairman, songs, prayers, introduction/conclusion duration, program-part titles and durations, students, assistants, and presenters.
- Export the schedule preview as a PNG image for sharing.
- Export a printable/shareable PDF.
- Cebuano labels and a navy-blue/white interface.

## S-140-CV template basis

The editor follows the supplied **S-140_CV new.docx** table content and ordering:

1. Header: congregation name and “Eskedyul sa Midweek nga Tigom”.
2. Date, “SENEMANANG PAGBASA SA BIBLIYA”, and “Tsirman”.
3. Opening song, opening prayer, and “Introduksiyon (1 min.)”.
4. “BAHANDI GIKAN SA PULONG SA DIYOS”: parts 1–3; the source labels part 2 “Espirituwal nga Bahandi” and part 3 “Pagbasa sa Bibliya”, with student field.
5. “MAGMAEPEKTIBO SA MINISTERYO”: parts 5–7, each with student and assistant.
6. “KRISTOHANONG PAGKINABUHI”: middle song, parts 8–10, “Tigdumala/Tigbasa”, “Konklusyon (3 min.)”, closing song and closing prayer.

The source template itself skips displayed number 4; the app preserves the numbering printed in the document rather than renumbering the rows.

## Requirements and run

- Flutter stable with Dart 3.6 or later.
- No cloud account, backend, API key, or `.env` file is required.

```bash
flutter pub get
flutter run
```

For Android:

```bash
flutter build apk --release
```

For web:

```bash
flutter build web --release
```

## Local data and exports

Schedules are stored in the app's local preferences. They remain available offline on the same app installation/browser profile. Clearing app storage, uninstalling the app, or clearing browser site data can erase saved schedules; this version does not yet include a separate backup/restore workflow. Export a PDF or PNG and keep a copy somewhere safe.

PNG export captures the schedule preview and opens the platform share sheet. PDF export generates a document and uses the platform print/share flow.

## Verification boundary

The source code was updated in an environment without the Flutter or Dart SDK. Therefore `flutter pub get`, analyzer, unit tests, Android packaging, web build, on-device offline persistence, and PNG/PDF share flows have **not** been run here. Run the commands above on a machine with Flutter installed and verify exports on the target Android device/browser before relying on it for a meeting.
