# BullMatch Web

Tasks: `BMI-APP-001`, `BMI-APP-002`

Mobile-first Thai UI for BullMatch Intelligence.

## Current state

The deployed frontend has a production application shell plus Supabase Auth login/session handling.

Public screens:
- Dashboard
- Bulls
- Bull Profile shell
- Matches
- Match Detail shell
- Profile / Settings

Authentication-required shells:
- Manual Entry
- Review Queue

Production domain data is intentionally not fabricated. Real-data areas remain empty until `BMI-APP-003` connects the controlled API boundary.

## Stack

- React 19
- TypeScript
- Vite 8
- dependency-light CSS
- hash navigation for static GitHub Pages hosting
- Supabase Auth REST for email/password session handling

## Authentication

The browser uses only:
- Supabase project URL
- Supabase publishable key
- short-lived user access token / refresh token returned after sign-in

The current app supports:
- email/password sign-in for pre-existing Auth accounts
- local session persistence
- access-token refresh
- session validation
- local logout
- redirect back to the originally requested protected screen after sign-in

There is deliberately **no public sign-up UI**.

An authenticated user is **not automatically an ADMIN**. BullMatch role authorization remains server-side through `bullmatch.app_users` and will be resolved by the API boundary in `BMI-APP-003`.

## Security boundary

Never place a Supabase secret/service-role key in this app.

Do not use `user_metadata` as BullMatch authorization.

Do not expose `bullmatch` or `bullmatch_private` privileged mutations directly to the browser just to make a screen operational.

`BMI-APP-003` must validate the user JWT and BullMatch membership/role at the controlled server/API boundary before returning protected data or executing mutations.

## Local commands

```bash
npm ci
npm run typecheck
npm run build
npm run dev
```

Vite 8 requires a supported modern Node release. CI uses Node 24.

## GitHub Pages

Vite base path:

`/BullMatch-Intelligence/`

Production URL:

`https://aodxx.github.io/BullMatch-Intelligence/`

`.github/workflows/web.yml` builds the app and deploys `apps/web/dist` on pushes to `main`.
