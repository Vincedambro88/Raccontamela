# Google Play readiness

## Android
- Package ID: com.vincedambro.raccontamela
- CI pins compileSdk and targetSdk to API 36.
- Production release must use Play App Signing or a protected upload key.

## Premium
- Product ID: raccontamela_premium
- One-time non-consumable purchase.
- Client purchase is validated server-side before entitlement is activated.
- Google Play service-account credentials stay in Supabase secrets.

## Required production configuration
- GOOGLE_PLAY_PACKAGE_NAME
- GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
- OPENAI_API_KEY

## Before production submission
- Complete Data Safety form.
- Complete target-audience/content declarations and applicable Families requirements.
- Publish a privacy policy covering authentication, story history and generated media.
- Configure the Play Billing product and package ID.
- Configure production signing.
