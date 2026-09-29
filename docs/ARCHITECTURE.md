# Architecture

## Client
Flutter Android application, structured so the same codebase can support future iOS delivery.

Layers:
- presentation
- application/state
- domain
- data
- services

## Backend
Supabase:
- Auth
- Postgres
- Row Level Security
- Edge Functions for privileged operations
- Storage for generated story assets where appropriate

## Core entities
- profiles
- stories
- story_scenes
- story_assets
- device_registrations
- premium_entitlements

## Security
The mobile client never receives service-role credentials.

Premium-only operations are authorized server-side using the authenticated user and validated entitlement.

Device registration and the two-device maximum are enforced transactionally server-side.

## Generation pipeline
1. Validate input.
2. Build localized story-generation request.
3. Generate story text.
4. Validate duration/length target.
5. Split story into scenes.
6. Generate color illustration for each scene.
7. For Premium, generate black-and-white printable variants.
8. For Premium narration, generate/obtain narration audio using the selected voice.
9. Persist metadata and assets.
10. Return a playable/readable story.

## Failure handling
Generation is asynchronous and resumable. A failed scene must not invalidate an otherwise completed story. The client receives explicit generation status and can retry failed work.

## Environments
Development/test and production must use separate backend configuration and Google Play product identifiers where required.
