# BullMatch Authorization Runbook

Task: `BMI-P1-004`
Status: Phase 1 authorization baseline

## 1. Source of truth

Shared Supabase Auth (`auth.users`) proves project-wide identity only.

BullMatch membership and role are stored in:

`bullmatch.app_users`

Allowed roles:
- `ADMIN`
- `REVIEWER`
- `VIEWER`

Allowed membership status:
- `ACTIVE`
- `SUSPENDED`

A person existing in `auth.users` is **not** automatically a BullMatch member.

## 2. Authorization rule

RLS uses `bullmatch.has_active_role(text[])`.

Important properties:
- `SECURITY INVOKER`
- reads the current `auth.uid()`
- checks the current row in `bullmatch.app_users`
- requires `status = 'ACTIVE'`
- never reads `raw_user_meta_data` / `user_metadata`
- role changes or suspension take effect on subsequent database requests without waiting for a custom role claim inside a JWT to expire

The MVP therefore does **not** require a Custom Access Token Auth Hook.

## 3. Browser permissions

`authenticated` receives read-only grants for BullMatch application tables.

RLS then narrows visibility:
- `ADMIN` / `REVIEWER`: may read canonical and review data needed by admin/review UI
- `VIEWER`: may read only verified/non-archived entities and verified/published matches
- non-member or suspended member: no BullMatch domain/review rows

No browser role receives INSERT/UPDATE/DELETE privileges on canonical/review tables in this phase.

`bullmatch_private` remains unavailable to `anon` and `authenticated` at the schema boundary.

## 4. First ADMIN bootstrap

Do not implement “first person to sign up becomes admin”. That creates a takeover race.

The first administrator is created only after a real Supabase Auth account exists and its identity is verified by a trusted operator.

### Step A — create/sign in through Supabase Auth

Use the application/Auth flow, not a manual insert into `auth.users`.

### Step B — identify the exact Auth UUID

Run from a trusted SQL/admin context:

```sql
select id, email, created_at
from auth.users
order by created_at;
```

Verify that the selected account belongs to the intended administrator.

### Step C — add BullMatch membership

Using the exact verified UUID:

```sql
insert into bullmatch.app_users (
  user_id,
  display_name,
  role,
  status
)
values (
  '<EXACT_AUTH_USER_UUID>'::uuid,
  '<DISPLAY_NAME>',
  'ADMIN',
  'ACTIVE'
)
on conflict (user_id) do update
set display_name = excluded.display_name,
    role = excluded.role,
    status = excluded.status,
    updated_at = now();
```

This SQL is for a trusted database/server operator only. It must never be exposed as a browser RPC.

## 5. Adding REVIEWER / VIEWER later

The eventual admin backend may create or change `bullmatch.app_users` memberships using server credentials after checking the acting ADMIN.

Do not grant direct browser writes to `app_users`.

## 6. Suspension

Set:

```sql
update bullmatch.app_users
set status = 'SUSPENDED', updated_at = now()
where user_id = '<AUTH_USER_UUID>'::uuid;
```

A suspended account may still possess a valid Supabase Auth session, but BullMatch role checks return false immediately on subsequent database requests.

For account compromise, also revoke/sign out Auth sessions using the supported Supabase Auth admin flow.

## 7. Role-change safety

Never authorize from:
- `raw_user_meta_data`
- browser-editable user metadata
- a client-provided role string
- email address alone

The canonical application role is `bullmatch.app_users.role`.

## 8. Current operational state

At implementation time (2026-09-06), the shared Supabase project had zero `auth.users` rows, so no production BullMatch membership was created by this task.

This is intentional: the authorization system is ready, but the first administrator is not fabricated.
