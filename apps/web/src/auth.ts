const SUPABASE_URL = 'https://kaanguobjhlusjvgbowt.supabase.co'
// Publishable keys are intentionally safe for browser use. Never replace this with a secret/service-role key.
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_8PGBe264vc1Y4LHNn9HvHQ_f1gZTfNG'
const STORAGE_KEY = 'bullmatch.auth.session.v1'
const EXPIRY_SKEW_SECONDS = 60

export type AuthUser = {
  id: string
  email?: string | null
  phone?: string | null
}

export type AuthSession = {
  access_token: string
  refresh_token: string
  expires_at: number
  token_type: string
  user: AuthUser
}

type TokenResponse = {
  access_token: string
  refresh_token: string
  expires_in?: number
  expires_at?: number
  token_type?: string
  user: AuthUser
}

function headers(accessToken?: string): HeadersInit {
  return {
    apikey: SUPABASE_PUBLISHABLE_KEY,
    'Content-Type': 'application/json',
    ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
  }
}

async function readError(response: Response): Promise<string> {
  try {
    const body = await response.json() as Record<string, unknown>
    const message = body.msg ?? body.message ?? body.error_description ?? body.error
    if (typeof message === 'string' && message.trim()) return message
  } catch {
    // Fall through to a stable localized message.
  }
  return `Supabase Auth ตอบกลับด้วยสถานะ ${response.status}`
}

function normalizeSession(data: TokenResponse): AuthSession {
  const expiresAt = data.expires_at ?? Math.floor(Date.now() / 1000) + (data.expires_in ?? 3600)
  return {
    access_token: data.access_token,
    refresh_token: data.refresh_token,
    expires_at: expiresAt,
    token_type: data.token_type ?? 'bearer',
    user: data.user,
  }
}

function saveSession(session: AuthSession | null) {
  if (session) localStorage.setItem(STORAGE_KEY, JSON.stringify(session))
  else localStorage.removeItem(STORAGE_KEY)
}

function loadStoredSession(): AuthSession | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as Partial<AuthSession>
    if (!parsed.access_token || !parsed.refresh_token || !parsed.expires_at || !parsed.user?.id) {
      saveSession(null)
      return null
    }
    return parsed as AuthSession
  } catch {
    saveSession(null)
    return null
  }
}

async function refreshSession(refreshToken: string): Promise<AuthSession> {
  const response = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=refresh_token`, {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ refresh_token: refreshToken }),
  })
  if (!response.ok) throw new Error(await readError(response))
  const session = normalizeSession(await response.json() as TokenResponse)
  saveSession(session)
  return session
}

async function validateUser(session: AuthSession): Promise<AuthSession> {
  const response = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    method: 'GET',
    headers: headers(session.access_token),
  })
  if (!response.ok) throw new Error(await readError(response))
  const user = await response.json() as AuthUser
  const validated = { ...session, user }
  saveSession(validated)
  return validated
}

export async function signInWithPassword(email: string, password: string): Promise<AuthSession> {
  const response = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ email: email.trim(), password }),
  })
  if (!response.ok) throw new Error(await readError(response))
  const session = normalizeSession(await response.json() as TokenResponse)
  saveSession(session)
  return session
}

export async function restoreSession(): Promise<AuthSession | null> {
  const stored = loadStoredSession()
  if (!stored) return null

  try {
    const now = Math.floor(Date.now() / 1000)
    const current = stored.expires_at <= now + EXPIRY_SKEW_SECONDS
      ? await refreshSession(stored.refresh_token)
      : stored
    return await validateUser(current)
  } catch {
    try {
      return await refreshSession(stored.refresh_token)
    } catch {
      saveSession(null)
      return null
    }
  }
}

export async function signOutLocal(session: AuthSession | null): Promise<void> {
  saveSession(null)
  if (!session?.access_token) return
  try {
    await fetch(`${SUPABASE_URL}/auth/v1/logout?scope=local`, {
      method: 'POST',
      headers: headers(session.access_token),
    })
  } catch {
    // Local sign-out has already completed; remote revocation is best-effort.
  }
}

export function getAccessToken(session: AuthSession | null): string | null {
  return session?.access_token ?? null
}
