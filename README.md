# powwow

> ⚠️ **Name note**: "powwow" is a work-in-progress name. User-facing strings in the codebase are marked with `// TODO(rename):` comments to make rebranding straightforward.

A **multiplatform** password and email breach checker — desktop (Windows, macOS, Linux) and PWA — built with Flutter. It uses k-anonymity to check your credentials against the [Have I Been Pwned](https://haveibeenpwned.com/) API without ever sending your full password to any server.

This project is an extension of and spiritual successor to the archived [SillyLittleTech/Pwned](https://github.com/SillyLittleTech/Pwned) CLI tool.

---

## Features

| Feature | Description |
|---------|-------------|
| 🔐 **Password breach check** | Uses SHA-1 + k-anonymity (only the first 5 chars of the hash are sent) against the free pwnedpasswords range API — no API key needed. |
| 📧 **Email breach check** | Checks an email address against all known HIBP breaches. Requires a [HIBP API key](https://haveibeenpwned.com/API/Key). |
| 💡 **Password suggestions** | When a breach is detected, generates cryptographically strong replacement passwords (random + passphrase styles). |
| 🌗 **Dark & Light mode** | Full support for system-preferred and user-toggled themes. |
| 🖥️ **Multiplatform** | Runs natively on Windows, macOS, and Linux; also available as a Progressive Web App (PWA) via GitHub Pages. |
| 🎨 **CookieCut design** | UI design language inspired by [SillyLittleTech/CookieCut](https://github.com/SillyLittleTech/CookieCut) — clean cards, rounded corners, teal accent palette. |

---

## Architecture

```
powwow/
├── lib/
│   ├── main.dart                   # App entry point
│   ├── app.dart                    # MaterialApp + theme wiring
│   ├── theme/
│   │   └── app_theme.dart          # Light/dark theme definitions
│   ├── models/
│   │   └── breach_result.dart      # Data model for API results
│   ├── services/
│   │   ├── pwned_api_service.dart  # HIBP API client (k-anonymity)
│   │   └── password_generator.dart # Secure password/passphrase generator
│   ├── screens/
│   │   └── home_screen.dart        # Main UI screen
│   └── widgets/
│       ├── check_type_selector.dart # Password/email toggle
│       └── result_card.dart         # Breach result display
├── web/                            # PWA assets (index.html, manifest.json)
├── linux/ windows/ macos/         # Platform-specific build configs
└── .github/workflows/
    ├── release.yml                 # Auto-release on push to main
    ├── pre-release.yml             # Pre-release on PR ready-for-review
    └── preview.yml                 # Firebase preview channel deploy
```

---

## Privacy & Security

- **Passwords are never sent over the network.** Only the first 5 characters of a SHA-1 hash are transmitted (k-anonymity model).
- The HIBP range API returns hundreds of potential hash matches; the app matches locally.
- Email checks require a paid HIBP API key entered by the user at runtime — it is never stored by the app.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.35.0
- Dart SDK ≥ 3.9.0 (bundled with Flutter)
- Platform tools: GTK 3 headers (Linux), Xcode (macOS), Visual Studio 2022 (Windows)

### Running locally

```bash
# Clone the repository
git clone https://github.com/SillyLittleTech/powwow.git
cd powwow

# Install dependencies
flutter pub get

# Run in debug mode (choose your target)
flutter run -d linux
flutter run -d macos
flutter run -d windows
flutter run -d chrome          # Web / PWA
```

### Building for release

```bash
flutter build linux --release
flutter build windows --release
flutter build macos --release
flutter build web --release --pwa-strategy offline-first
```

---

## CI / CD Workflows

| Workflow | Trigger | Action |
|----------|---------|--------|
| **Build & Release** (`release.yml`) | Push to `main` touching app files | Builds all platforms, creates a versioned GitHub Release, deploys PWA to GitHub Pages |
| **Pre-Release** (`pre-release.yml`) | PR marked ready-for-review | Builds all platforms, creates a pre-release. Skips (with a PR comment) if a pre-release for that version already exists |
| **Firebase Preview** (`preview.yml`) | Any PR | Deploys the web build to a Firebase Hosting preview channel (`slf-powwow`) |

Version numbers are read directly from `version:` in `pubspec.yaml` (format: `major.minor.patch+build`).

---

## Contributing

1. Fork the repo and create a feature branch from `main`.
2. Make your changes — all user-facing strings are annotated with `// TODO(rename):` for easy future rebranding.
3. Mark your PR as **Ready for Review** to trigger a pre-release build.
4. Once merged to `main`, a full release is built automatically.

---

## License

[MIT](LICENSE) © SillyLittleTech

