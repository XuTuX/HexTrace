# Honey Boo

Honey Boo is a Flutter puzzle game with Supabase-backed auth, synced scores, and ranking.

## Runtime Configuration

This app now expects runtime values through `--dart-define`.

Required values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## Google Sign-In Configuration

Google Sign-In client identifiers are configured natively:

- Android: `android/app/src/main/res/values/strings.xml`
- iOS: `ios/Runner/Info.plist`

## Android Signing

Release signing can be provided in either of these ways:

1. `android/key.properties`
2. Environment variables: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`

If signing values are missing, Gradle can still produce an unsigned release artifact for verification builds.

## Supabase Setup

Apply the SQL migration in `supabase/migrations/202604060001_hexor_core.sql` before deploying. It creates the required tables, constraints, indexes, triggers, RPCs, and RLS policies.
