# Hexor

Hexor is a Flutter puzzle game with Supabase-backed auth, synced scores, and ranking.

## Runtime Configuration

This app now expects runtime values through `--dart-define`.

Required values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_IOS_CLIENT_ID`

Example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=GOOGLE_WEB_CLIENT_ID=... \
  --dart-define=GOOGLE_IOS_CLIENT_ID=...
```

## Android Signing

Release signing can be provided in either of these ways:

1. `android/key.properties`
2. Environment variables: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`

If signing values are missing, Gradle can still produce an unsigned release artifact for verification builds.

## Supabase Setup

Apply the SQL migration in `supabase/migrations/202604060001_hexor_core.sql` before deploying. It creates the required tables, constraints, indexes, triggers, RPCs, and RLS policies.
