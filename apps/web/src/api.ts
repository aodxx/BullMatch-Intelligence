import { type AuthSession, SUPABASE_PUBLISHABLE_KEY, SUPABASE_URL } from './auth'

const API_URL = `${SUPABASE_URL}/functions/v1/bullmatch-api`

export type DashboardData = {
  bulls: number
  published_matches: number
  venues: number
  last_published_at: string | null
}

export type BullListItem = {
  id: string
  canonical_name: string
  home_province: string | null
  home_district: string | null
  color_description: string | null
  breed_description: string | null
  status: string
  camp_name: string | null
  owner_name: string | null
  published_matches: number
  statistical_matches: number
  wins: number
  losses: number
  draws: number
  no_results: number
  cancelled: number
  win_rate_pct: number | null
  last_match_at: string | null
  recent_form: string[]
}

export type BullHistoryRow = {
  match_id: string
  match_date: string | null
  date_precision: string
  match_number: number | null
  result: string | null
  result_type: string
  event_id: string | null
  event_name: string | null
  venue_id: string | null
  venue_name: string | null
  venue_province: string | null
  opponent_bull_id: string | null
  opponent_name: string | null
  opponent_weight_kg: number | null
  opponent_age_months_estimate: number | null
  published_at: string
}

export type BullProfileData = {
  bull: {
    id: string
    canonical_name: string
    birth_date: string | null
    birth_date_precision: string | null
    color_description: string | null
    breed_description: string | null
    home_province: string | null
    home_district: string | null
    status: string
    primary_image_ref: string | null
    camp: { id: string; name: string; province: string | null; district: string | null } | null
    owner: { id: string; name: string; province: string | null; district: string | null } | null
  }
  stats: BullListItem
  recent_form: string[]
  history: BullHistoryRow[]
}

export type MatchParticipant = {
  id: string
  bull_id: string
  side: string | null
  display_name: string
  primary_image_ref: string | null
  weight_kg: number | null
  age_months_estimate: number | null
  result: string | null
  camp_id_snapshot?: string | null
  owner_id_snapshot?: string | null
}

export type MatchItem = {
  id: string
  match_date: string | null
  date_precision: string
  match_number: number | null
  status: string
  duration_seconds: number | null
  result_detail: string | null
  published_at: string
  event: { id: string; name: string | null; event_date: string | null; start_time?: string | null } | null
  venue: { id: string; name: string; province: string | null; district: string | null } | null
  result: { type: string; reason: string | null; verified_at: string; winner_participant_id?: string | null }
  participants: MatchParticipant[]
}

export type VenueItem = { id: string; name: string; province: string | null; district: string | null; status: string }

export type Membership = {
  member: boolean
  user_id: string
  display_name: string | null
  role: 'ADMIN' | 'REVIEWER' | 'VIEWER' | null
  status: string | null
  active: boolean
}

export type MeData = {
  user: { id: string; email: string | null }
  membership: Membership
  request_id: string
}

type ApiEnvelope<T> = { data: T; request_id: string }

async function readError(response: Response): Promise<string> {
  try {
    const body = await response.json() as Record<string, unknown>
    const message = body.message ?? body.error
    if (typeof message === 'string' && message.trim()) return message
  } catch {
    // Fall through.
  }
  return `BullMatch API ตอบกลับด้วยสถานะ ${response.status}`
}

async function request<T>(url: URL, options: RequestInit = {}): Promise<T> {
  const response = await fetch(url, {
    ...options,
    headers: {
      apikey: SUPABASE_PUBLISHABLE_KEY,
      'Content-Type': 'application/json',
      ...(options.headers ?? {}),
    },
  })
  if (!response.ok) throw new Error(await readError(response))
  return response.json() as Promise<T>
}

async function publicQuery<T>(resource: string, params: Record<string, string | undefined> = {}): Promise<T> {
  const url = new URL(API_URL)
  url.searchParams.set('resource', resource)
  for (const [key, value] of Object.entries(params)) if (value) url.searchParams.set(key, value)
  const response = await request<ApiEnvelope<T>>(url)
  return response.data
}

export const getDashboard = () => publicQuery<DashboardData>('dashboard')
export const getBulls = (search?: string) => publicQuery<BullListItem[]>('bulls', { search })
export const getBull = (id: string) => publicQuery<BullProfileData | null>('bull', { id })
export const getMatches = () => publicQuery<MatchItem[]>('matches')
export const getMatch = (id: string) => publicQuery<MatchItem | null>('match', { id })
export const getVenues = () => publicQuery<VenueItem[]>('venues')

export async function getMe(session: AuthSession): Promise<MeData> {
  const url = new URL(API_URL)
  url.searchParams.set('resource', 'me')
  return request<MeData>(url, { headers: { Authorization: `Bearer ${session.access_token}` } })
}

export async function adminCommand<T = { ok: boolean; operation: string; id: string }>(session: AuthSession, operation: string, payload: Record<string, unknown>): Promise<T> {
  const response = await request<ApiEnvelope<T>>(new URL(API_URL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${session.access_token}` },
    body: JSON.stringify({ operation, payload }),
  })
  return response.data
}
