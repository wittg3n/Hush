# Hush (Flutter)

A modern black-and-white Flutter rewrite of **Hush**, featuring shadcn-inspired components. The app focuses on keeping your primary media player quiet when other audio sources take over.

## Current experience
- Choose a target media player (mock data for now).
- Decide whether to pause playback or duck volume when competing audio is detected.
- Start/stop monitoring and view a concise activity log.

## Running
This project uses Flutter 3.3+.

```bash
flutter pub get
flutter run
```

## Notes
The audio control layer is a placeholder service designed for UI demonstration. Connect it to platform-specific audio controls or background isolates to mirror the original desktop automation behavior.
