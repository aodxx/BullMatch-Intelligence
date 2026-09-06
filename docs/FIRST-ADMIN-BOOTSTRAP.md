# First Production ADMIN Bootstrap

Task: `BMI-OPS-002`

This runbook creates the first real BullMatch administrator without opening public sign-up or sharing a password with an agent/developer.

## Status

**COMPLETED — 2026-09-06**

The intended real Supabase Auth identity in project `kaanguobjhlusjvgbowt` has been linked to `bullmatch.app_users` as `ADMIN / ACTIVE`.

Verification completed:
- Auth identity exists
- email confirmation is complete
- exact Auth UUID is linked to BullMatch membership
- `bullmatch_api_member` returns `member=true`, `role=ADMIN`, `status=ACTIVE`, `active=true`
- authenticated role check reports ADMIN authorized

No email address, password, access token, refresh token, service-role key, or Auth UUID is recorded in this public repository.

## Preconditions

- `BMI-APP-003` is deployed.
- Supabase project: `aodxx's Project` (`kaanguobjhlusjvgbowt`).
- `bullmatch-api` is ACTIVE.

## Owner action — create the Auth identity

In the Supabase Dashboard:

1. Open project **aodxx's Project**.
2. Open **Authentication**.
3. Open **Users**.
4. Choose **Add user** / **Create new user**.
5. Enter the owner's real email address and a strong password.
6. Create the user.

### Never share

Do not send or commit:
- password
- access token
- refresh token
- service-role key
- any secret key

## Maintainer action — bind the exact Auth UUID

The maintainer must identify the intended Auth identity and use its exact `auth.users.id` UUID as the stable application membership key.

```sql
insert into bullmatch.app_users (
  user_id,
  display_name,
  role,
  status
)
values (
  '<EXACT_AUTH_USER_UUID>',
  'Primary Admin',
  'ADMIN',
  'ACTIVE'
)
on conflict (user_id) do update
set role = 'ADMIN',
    status = 'ACTIVE',
    updated_at = now();
```

Do not use an email string as a BullMatch foreign key. The stable `auth.users.id` UUID is authoritative.

## Verification

Verify database membership:

```sql
select user_id, display_name, role, status
from bullmatch.app_users
where user_id = '<EXACT_AUTH_USER_UUID>';
```

Expected:
- role = `ADMIN`
- status = `ACTIVE`

Verify the service boundary:

```sql
select public.bullmatch_api_member('<EXACT_AUTH_USER_UUID>'::uuid);
```

Expected membership payload:
- `member: true`
- `role: ADMIN`
- `status: ACTIVE`
- `active: true`

## Owner verification in the app

1. Open `https://aodxx.github.io/BullMatch-Intelligence/`.
2. Sign in with the account just created.
3. If the account was already signed in before membership was added, refresh the page or sign out/in once.
4. Open **Settings**.
5. Confirm BullMatch role shows `ADMIN / ACTIVE`.
6. Open **บันทึก** and confirm the page no longer shows the no-ADMIN access gate.

## Security model

Creating a Supabase Auth account alone does not grant BullMatch access.

Authorization requires a separate row in `bullmatch.app_users`. This prevents any future Auth user from becoming ADMIN merely by signing in.

There is no public role picker and no public sign-up UI.

## Disable access without deleting identity

Prefer deactivation over deleting audit history:

```sql
update bullmatch.app_users
set status = 'INACTIVE', updated_at = now()
where user_id = '<AUTH_USER_UUID>';
```

This preserves the Auth identity and historical audit references while immediately failing ACTIVE membership checks.
