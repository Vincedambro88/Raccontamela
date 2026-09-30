# Raccontamela

Flutter app for creating personalized children's stories.

## Current implementation

- Flutter + Riverpod foundation
- Italian, English, French, Spanish and German localization
- Story creation form with:
  - protagonist name chosen for each story
  - setting chosen for each story
  - animal selected for each story
  - up to 4 protagonist friends
- First working story-generation vertical slice with five scenes
- Story reader with duration/word-count metadata
- Supabase bootstrap through build-time `--dart-define` values
- Dedicated Supabase project: `psbdgeeknuxmdbvblvrx`
- Supabase profile trigger and transactional two-device registration function
- GitHub Actions Flutter analyze/test workflow
- Public repository with secrets excluded from version control

## Dynamic story model

Every new story is generated from the current combination of protagonist + setting + animal. These are runtime inputs, not fixed attributes of the 500-story editorial catalog. The selected animal is a required first-class parameter and must remain species-consistent and causally relevant throughout the eight pages.

## Product split

### Free

- Create stories
- Color story illustrations
- No account required for basic story creation

### Premium

- One-time Google Play purchase
- Narration with selectable voices
- Black-and-white printable/coloring illustrations
- Account and cloud story history
- Maximum two registered devices per account

## Important implementation rule

The current local story generator is a development vertical slice. The production generator will be provider-backed on the server. Story generation, image generation, narration and Google Play entitlement validation must not require private API credentials in the Android client.

Google Play purchase handling uses the Flutter `in_app_purchase` package. Purchases must be verified server-side before Premium is granted.

## Supabase

Project URL:

`https://psbdgeeknuxmdbvblvrx.supabase.co`

Only a Supabase publishable/anon key may be supplied to the client. Never commit service-role keys, Google Play service-account credentials, signing keys or model-provider secrets.

## Local run

Create the generated Flutter platform project and run:

```bash
flutter create . --platforms=android
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://psbdgeeknuxmdbvblvrx.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_KEY
```

The app can also start without Supabase build-time values while working on the local story-generation slice.

## Next implementation blocks

1. Server-backed story generation with provider abstraction.
2. Color scene image generation and Storage delivery.
3. Premium black-and-white printable assets.
4. Account/Auth and cloud history.
5. Google Play one-time purchase + server validation.
6. Premium narration/voice selection.
7. Android application configuration, privacy/data-safety flows and Play release hardening.

<!-- Internal APK build trigger: Premium backend test validation. -->


<!-- Raccontamela UI/premium refinement build trigger -->
