# Our Commitment — Flutter MVP

## What is included
- Arabic RTL Flutter app shell.
- Local/offline task storage using SharedPreferences.
- Starter tasks based on the requirements discussed.
- Shared / personal task categories.
- Add, edit, archive tasks.
- Daily, alternate-day, Friday, Saturday and one-time frequency choices.
- Daily completion checklist.
- Weighted points and completion percentage.
- Midnight day boundary (device local date; Egypt timezone should be enforced in production).

## Important limitations of this MVP
- Cloud sync between the two phones is NOT implemented yet.
- Friend's progress is not yet fetched from another device.
- Weekly comparison, streak history, subtask tracking, export/import and conflict resolution are planned next.
- The alternate-day schedule currently uses a fixed anchor date in the prototype; make the anchor configurable before production.
- This source has not been compiled or tested in an Android build environment here.

## Run
1. Install Flutter SDK and Android Studio.
2. Extract this folder.
3. Run `flutter pub get`.
4. Run `flutter run` on an Android device or emulator.
5. To build an APK: `flutter build apk --release`.

## Next engineering milestones
1. Replace SharedPreferences with SQLite for durable structured local data.
2. Add stable user/team IDs and Firebase Authentication.
3. Add Firestore sync + an offline outbox and conflict resolution.
4. Add weekly history, subtasks, backup/restore and a proper settings screen.
5. Add tests for recurrence, scoring, date boundaries and sync conflicts.

## Product rules
- Two participants; both can manage all shared and personal tasks.
- Shared task edits sync to both devices when connected.
- Every participant has an independent completion record.
- Day closes at 00:00 (midnight).
- Editing/archiving a task must not erase historical completions.
