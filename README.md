# SmartSpend - Personal Expense Tracker

## Overview

**SmartSpend** is an intelligent mobile expense tracking application built with Flutter and Supabase. Designed to be simple, smart, and motivating, it helps users manage their personal finances with AI-powered insights, gamification, and adaptive budgeting for variable income.

**Author:** Zhmuryk Andrii | [LinkedIn Profile](https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/)

---

## Key Features

### Core Capabilities
- **Quick Expense Entry**: Add expenses in under 10 seconds
- **Smart Categorization**: Customizable categories with icons and colors
- **Budget Management**: Global and per-category budgets with real-time alerts
- **Visual Analytics**: Clear charts (daily/weekly/monthly trends)
- **Multi-Account Support**: Track multiple wallets and bank accounts

### AI-Powered Intelligence
- **Smart Assistant**: Personalized financial advice based on spending habits
- **Budget Recommendations**: AI-generated budget suggestions
- **Expense Insights**: Automated pattern detection and anomaly alerts
- **Natural Language Processing**: Chat-based expense queries

### Financial Goals
- **Goal Tracking**: Visual progress for savings targets
- **Milestone Celebrations**: Animated achievements on goal completion
- **Smart Suggestions**: AI recommendations for reaching goals faster

### Adaptive Budgeting
- **Variable Income Mode**: Dynamic daily budgets based on earnings
- **Rollover System**: Unused budget carries to next day
- **Flexible Adjustments**: Real-time budget recalculation

### Gamification
- **Streak Tracking**: Maintain daily logging habits
- **Achievement Badges**: Unlock rewards for financial milestones
- **Monthly Challenges**: Budget challenges with progress tracking
- **Leaderboards**: Compete with family members (Premium)

### Premium Features
- **Family Sharing**: Manage household budgets together with role-based access
- **Advanced Reports**: PDF/CSV export with customizable date ranges
- **Unlimited Goals**: Track multiple savings targets simultaneously
- **AI Assistant**: Unlimited chat queries and insights
- **Receipt Scanning**: OCR text recognition from photos
- **Cloud Backup**: Automatic sync across devices
- **Priority Support**: Dedicated customer service

### Security & Privacy
- **Biometric Authentication**: Face ID / Fingerprint login
- **End-to-End Encryption**: Local data encryption with AES-256
- **Secure Storage**: Sensitive data stored in system keychain
- **Offline Mode**: SQLite local cache for offline access
- **Data Export**: GDPR-compliant data portability

---

## Technology Stack

### Frontend
- **Flutter 3.2+** - Cross-platform mobile framework
- **Provider 6.1** - State management
- **go_router 13.0** - Type-safe navigation
- **fl_chart 0.66** - Beautiful charts and graphs
- **google_fonts 6.1** - Custom typography
- **lottie 3.0** - Smooth animations

### Backend & Database
- **Supabase** - PostgreSQL database, Authentication, Storage
- **SQLite (sqflite 2.3)** - Offline local cache
- **Shared Preferences** - Lightweight key-value storage

### AI & ML
- **Google ML Kit** - OCR text recognition for receipts
- **Custom NLP Engine** - Natural language expense queries
- **TensorFlow Lite** (planned) - On-device prediction models

### Security
- **flutter_secure_storage 9.2** - Encrypted key storage
- **local_auth 2.2** - Biometric authentication
- **encrypt 5.0** - AES encryption for sensitive data
- **crypto 3.0** - Hash functions and cryptographic operations

### Monetization & Analytics
- **RevenueCat (purchases_flutter 6.30)** - In-app subscription management
- **Google Mobile Ads 5.2** - Non-intrusive banner ads (free tier)
- **Sentry 8.1** - Crash reporting and performance monitoring

### Additional Features
- **flutter_local_notifications 16.3** - Budget alerts and reminders
- **home_widget 0.6** - iOS/Android home screen widgets
- **workmanager 0.5** - Background task scheduling
- **pdf 3.10 + printing 5.12** - Report generation and sharing

---

## Quick Start Guide

### Prerequisites
- Flutter SDK 3.2.0 or higher
- Dart 3.0+
- Android Studio / Xcode (for mobile development)
- Supabase account (free tier available)

### Setup Steps

**1. Clone Repository**
```bash
git clone https://github.com/Nostradam4ik/MobApp.git
cd MobApp
```

**2. Install Dependencies**
```bash
flutter pub get
```

**3. Supabase Configuration**

Create a Supabase project at [supabase.com](https://supabase.com) and run the migrations:

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your Supabase credentials
SUPABASE_URL=your-project-url
SUPABASE_ANON_KEY=your-anon-key
```

Execute the SQL migrations from `supabase/migrations/` in your Supabase dashboard.

**4. Run the App**

```bash
# Development mode with hot reload
flutter run

# Release build for Android
flutter build apk --release

# Release build for iOS
flutter build ios --release
```

---

## Supabase Database Schema

The app uses the following main tables:

- **profiles** - User profiles with preferences and settings
- **expenses** - Transaction records with categorization
- **budgets** - Budget limits (global and per-category)
- **categories** - Customizable expense categories
- **goals** - Financial savings targets
- **achievements** - Gamification badges and streaks
- **accounts** - Multi-account wallet management
- **family_groups** - Family sharing memberships (Premium)
- **recurring_expenses** - Subscription and recurring payments

Refer to `supabase/migrations/` for complete schema definitions.

---

## Project Structure

```
smartspend/
├── lib/
│   ├── core/
│   │   ├── config/          # App configuration and Supabase setup
│   │   ├── constants/       # App-wide constants
│   │   ├── extensions/      # Dart extensions (Date, Context)
│   │   ├── router/          # Navigation configuration
│   │   ├── theme/           # Material theme and colors
│   │   └── utils/           # Formatters and validators
│   ├── data/
│   │   └── models/          # Data models (Expense, Budget, Goal, etc.)
│   ├── providers/           # State management (Provider pattern)
│   ├── screens/             # UI screens organized by feature
│   │   ├── auth/            # Login, Register, Forgot Password
│   │   ├── home/            # Dashboard with quick actions
│   │   ├── expenses/        # Expense list and detail views
│   │   ├── budgets/         # Budget management
│   │   ├── goals/           # Financial goal tracking
│   │   ├── stats/           # Charts and analytics
│   │   ├── assistant/       # AI chat assistant
│   │   ├── premium/         # Subscription management
│   │   └── settings/        # App preferences
│   ├── services/            # Business logic layer
│   │   ├── supabase_service.dart
│   │   ├── ai_assistant_service.dart
│   │   ├── export_service.dart
│   │   └── notification_service.dart
│   ├── widgets/             # Reusable UI components
│   │   ├── common/          # Buttons, text fields, cards
│   │   ├── expense/         # Expense-specific widgets
│   │   └── budget/          # Budget progress bars
│   └── main.dart            # App entry point
├── supabase/
│   └── migrations/          # Database schema migrations
├── assets/
│   ├── images/              # App icons and graphics
│   ├── lottie/              # Animation files
│   └── fonts/               # Custom fonts
├── test/                    # Unit and widget tests
├── integration_test/        # End-to-end tests
└── pubspec.yaml             # Dependencies and assets
```

---

## Environment Configuration

Create a `.env` file in the root directory:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# RevenueCat (In-App Purchases)
REVENUECAT_API_KEY_ANDROID=your-android-key
REVENUECAT_API_KEY_IOS=your-ios-key

# Google Mobile Ads
ADMOB_APP_ID_ANDROID=ca-app-pub-xxxxx
ADMOB_APP_ID_IOS=ca-app-pub-xxxxx

# Sentry (Crash Reporting)
SENTRY_DSN=https://your-sentry-dsn
```

**Security Note:** Never commit `.env` to version control. Use `.env.example` as a template.

---

## Monetization Strategy

### Free Tier
- ✅ Unlimited expense tracking
- ✅ Budget management (5 budgets)
- ✅ Basic statistics and charts
- ✅ Up to 3 financial goals
- ✅ Daily streak tracking
- ⚠️ Banner ads (non-intrusive)

### Premium Tier (€3-5/month)
- ✅ **Ad-Free Experience**
- ✅ **Unlimited Budgets & Goals**
- ✅ **AI Assistant** - Unlimited chat queries
- ✅ **Family Sharing** - Up to 5 members
- ✅ **Receipt Scanning** - OCR text recognition
- ✅ **Advanced Reports** - PDF/CSV export
- ✅ **Cloud Backup** - Automatic sync
- ✅ **Priority Support** - 24-hour response time

---

## Development Workflow

### Running Tests

```bash
# Unit tests
flutter test

# Widget tests with coverage
flutter test --coverage

# Integration tests (requires emulator/device)
flutter test integration_test/app_test.dart
```

### Code Quality

```bash
# Analyze code for issues
flutter analyze

# Format code
dart format lib/

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

### Building for Production

**Android:**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS:**
```bash
flutter build ipa --release
# Output: build/ios/ipa/smartspend.ipa
```

---

## Deployment

### Google Play Store
1. Create app listing at [play.google.com/console](https://play.google.com/console)
2. Upload `app-release.aab` from build output
3. Configure store listing with screenshots and description
4. Submit for review

### Apple App Store
1. Register app at [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Upload `.ipa` via Xcode or Transporter
3. Complete metadata and submit for review

---

## Roadmap

### Version 1.1 (Q1 2026)
- [ ] Smart receipt scanning with auto-categorization
- [ ] Shared budgets for couples
- [ ] Apple Watch companion app
- [ ] Voice input for quick expense logging

### Version 2.0 (Q2 2026)
- [ ] Investment portfolio tracking
- [ ] Bill splitting with friends
- [ ] Cryptocurrency wallet integration
- [ ] Multi-currency support with live exchange rates

---

## Privacy & Security

SmartSpend takes your financial privacy seriously:

- **Local-First Architecture**: All sensitive data stored encrypted on device
- **Zero-Knowledge Encryption**: Server cannot decrypt your financial data
- **Minimal Data Collection**: Only essential info for app functionality
- **No Third-Party Tracking**: No analytics SDKs except Sentry (opt-in)
- **GDPR Compliant**: Right to access, export, and delete your data
- **Open Source Security**: Codebase available for audit

---

## Browser & Platform Support

### Mobile Platforms
- Android 7.0 (API 24) and above
- iOS 12.0 and above

### Tested Devices
- Google Pixel 6/7/8 series
- Samsung Galaxy S21/S22/S23
- iPhone 12/13/14/15 series
- iPad Pro (2020+)

---

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Note:** Please ensure all tests pass and code is formatted before submitting.

---

## License

**All Rights Reserved** - Copyright (c) 2024-2025 Zhmuryk Andrii

This project is for educational and portfolio purposes. Commercial use, redistribution, or derivative works are prohibited without explicit written permission from the author.

For licensing inquiries, please contact via [LinkedIn](https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/).

---

## Support & Contact

- **LinkedIn:** [Andrii Zhmuryk](https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/)
- **GitHub Issues:** [Report bugs or request features](https://github.com/Nostradam4ik/MobApp/issues)
- **Email:** Available on LinkedIn profile

---

## Acknowledgments

- Flutter team for the amazing cross-platform framework
- Supabase for providing a powerful open-source Firebase alternative
- Contributors and testers who helped improve the app
- The open-source community for inspiration and packages

---

**⭐ If you find this project useful, please consider starring it on GitHub!**
