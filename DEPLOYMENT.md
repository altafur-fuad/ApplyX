# ApplyX — Deployment Guide

**Version:** 1.0.0

This document covers development → staging → Android/iOS production.

## 1. Environment Strategy

```text
local
  ↓
staging
  ↓
production
```

Each environment should have separate:

- Supabase project/database;
- backend deployment/config;
- AI/search credentials;
- storage buckets where practical;
- analytics/crash environment.

## 2. Pre-Release Checklist

```text
[ ] Product core journey works
[ ] No P0/P1 blocker
[ ] Flutter analyze passes
[ ] Flutter tests pass
[ ] Backend tests pass
[ ] Release API points to staging/production intentionally
[ ] No development secrets in release
[ ] RLS verified
[ ] Account deletion works
[ ] Privacy policy live
[ ] AI vendor/data processing reviewed
[ ] Reviewer/demo account works
[ ] Screenshots and store text ready
```

## 3. Android

### Build

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

### Release checks

Confirm:

- application ID is final;
- release signing is configured;
- keystore credentials are backed up securely;
- target/compile SDK satisfies current Google Play requirements;
- production backend is reachable;
- deep links/notifications work;
- privacy policy and Data Safety declaration are accurate.

### Play Console

```text
Create app
→ Store listing
→ App content
→ Data Safety
→ Testing track
→ Upload AAB
→ Test
→ Production release
```

For eligible newer personal developer accounts, check the current Play testing/production-access requirements before planning the release date.

## 4. iOS

### Build environment

Use a supported macOS/Xcode environment or macOS CI/CD service.

### Build

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build ipa --release
```

### App Store Connect

```text
Create App Record
→ Bundle ID
→ Upload build
→ TestFlight
→ Metadata
→ App Privacy
→ Review information
→ Submit for Review
→ Release
```

## 5. Store Reviewer Access

If login is required, provide a stable test account and exact navigation steps.

Example:

```text
Email: review@applyx.example
Password: <stored outside repository>

Steps:
1. Open ApplyX.
2. Login.
3. Open Goals.
4. Open the demo goal.
5. Tap Start Agent.
6. Open the results.
```

Never publish real user data in a reviewer account.

## 6. Release Versioning

Use semantic-style application versions plus platform build numbers.

```text
1.0.0 / build 1
1.0.1 / build 2
1.1.0 / build 3
```

Every store upload must have a unique platform build number.

## 7. Rollback / Recovery

Before production release:

- record current backend version;
- know how to disable a failing agent workflow;
- keep previous mobile build available;
- maintain database backups/recovery procedures;
- avoid irreversible migrations without a rollback plan.

## 8. Post-Launch Monitoring

Monitor:

- crash rate;
- API error rate;
- agent failure rate;
- tool timeout rate;
- approval rejection rate;
- notification delivery;
- AI usage/cost;
- critical user feedback.

## 9. Emergency Response

If a critical issue appears:

```text
Detect
→ Stop affected workflow
→ Protect user data
→ Identify scope
→ Patch
→ Test
→ Release hotfix
→ Monitor
```
