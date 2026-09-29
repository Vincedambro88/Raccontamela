# Raccontamela

Raccontamela is a multilingual children's storytelling app.

## Product model

### Free
- Create new stories on demand.
- Inputs: protagonist name, setting, story city, up to 4 protagonist friends, animal friends.
- Story duration target: approximately 5–6 minutes.
- Illustrated story scenes in full color.

### Premium
- Everything in Free.
- Narration with selectable voices.
- Black-and-white printable illustrations for children to color.
- Account and cloud story history.
- Same account usable on a maximum of 2 devices.
- Premium entitlement managed through Google Play Billing.

## Languages
Italian, English, French, Spanish and German.

## Architecture principles
- No secrets committed to Git.
- Free/Premium entitlement enforced server-side where appropriate.
- Supabase is a dedicated backend for Raccontamela.
- Google Play purchase state is the source of truth for Android entitlement validation.
- Cloud data is protected with Supabase Row Level Security.
- Device limit is enforced server-side.
- Localization is designed from the first build.
- Production configuration is separated from development/test configuration.

## Backend
Dedicated Supabase project: Raccontamela.

## Repository
Dedicated GitHub repository; this repository is intentionally independent from MoneyFamily.
