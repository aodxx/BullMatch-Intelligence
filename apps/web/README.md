# BullMatch Web

Task: `BMI-APP-001`

Mobile-first Thai UI for BullMatch Intelligence.

## Current state

This is the **frontend foundation**, not the final connected application.

Included screens:
- Dashboard
- Bulls
- Bull Profile shell
- Matches
- Match Detail shell
- Manual Entry shell
- Review Queue shell
- Profile / Settings

Production data is intentionally not fabricated. Empty states remain visible until the secure API/read surface is implemented.

## Stack

- React 19
- TypeScript
- Vite 8
- dependency-light CSS
- hash navigation for static GitHub Pages hosting

## Local commands

```bash
npm install
npm run typecheck
npm run build
npm run dev
```

Vite 8 requires a supported modern Node release. CI uses Node 24.

## Security boundary

Do **not** place a Supabase `service_role` key in this app.

Do **not** expose the existing `bullmatch` SECURITY DEFINER mutation functions directly just to make the UI work.

Data/Auth wiring belongs to later tasks after the project defines a controlled exposed API/read surface.

## GitHub Pages

Vite base path is:

`/BullMatch-Intelligence/`

`.github/workflows/web.yml` builds this app and deploys `apps/web/dist` on pushes to `main` once GitHub Pages is configured to use GitHub Actions.
