# SwarVed

A private music player built for one person. It plays audio straight from a
local folder (no account, no server) and carries a few personal things on
top: notes, dedications and a shared logbook. Windows and Android, one
Flutter codebase.

Wine and rose with sunlight gold. The design plan lives in the theme
preview HTML; the full idea is in `SwarVed — Project Brief.md`.

## Run

    flutter pub get
    flutter run -d windows     # or pick an Android device
    flutter analyze
    flutter test

## Layout

    lib/
      content/    words.dart (her voice), labels.dart (plain UI labels)
      models/     plain data: Track, ListenEntry, LibraryProblem
      screens/    home/, us/, library_screen, now_playing_screen
      services/   library, player, stats, storage permission
      theme/      colors, typography, shape, responsive, app_theme
      utils/      small pure helpers
      widgets/    reusable pieces shared by screens
    test/         mirrors lib/

## Rules for the code

- One file, one job.
- Every colour comes from `AppColors`, every text style from `AppType`,
  every corner from `AppShape`. No raw values in screens.
- Every word the app says lives in `words.dart` or `labels.dart`.
- Fonts are bundled in `assets/google_fonts` and never fetched online.
- Personal content stays on the device.
- Every icon is a `SwarGlyph` drawn by `SwarIcon`. No `Icons.*` in the app.

## App icon

The icon files are in `assets/branding/`. Replace `app_icon.png` and
`app_icon_foreground.png`, then run:

    dart run flutter_launcher_icons