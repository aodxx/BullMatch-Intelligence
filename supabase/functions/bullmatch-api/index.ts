const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')

if (!SUPABASE_URL || !SERVICE_ROLE_KEY || !ANON_KEY) throw new Error('Required Supabase runtime environment variables are missing')

const ALLOWED_ORIGINS = new Set(['https://aodxx.github.io','http://localhost:5173','http://127.0.0.1:5173'])
class ApiError extends Error { constructor(public status: number, message: string, public details?: unknown) { super(message) } }

function corsHeaders(req: Request) {
  const origin = req.headers.get('origin') ?? ''
  const allowOrigin = ALLOWED_ORIGINS.has(origin) ? origin : 'https://aodxx.github.io'
  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    Vary: 'Origin',
    'X-Content-Type-Options': 'nosniff',
  }
}
function respond(req: Request, status: number, body: unknown, cache='no-store') {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders(req), 'Content-Type':'application/json; charset=utf-8', 'Cache-Control':cache } })
}
async function parseJsonResponse(response: Response) {
  const text = await response.text(); if (!text) return null
  try { return JSON.parse(text) } catch { return { message:text } }
}
async function rpc(functionName: string, payload: Record<string, unknown>) {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${functionName}`, {
    method:'POST', headers:{ apikey:SERVICE_ROLE_KEY, Authorization:`Bearer ${SERVICE_ROLE_KEY}`, 'Content-Type':'application/json' }, body:JSON.stringify(payload),
  })
  const data = await parseJsonResponse(response)
  if (!response.ok) {
    const message = typeof data?.message === 'string' ? data.message : 'Database request failed'
    const code = typeof data?.code === 'string' ? data.code : ''
    throw new ApiError(code === '42501' || /ACTIVE ADMIN|permission denied/i.test(message) ? 403 : 400, message, data)
  }
  return data
}
async function authenticatedUser(req: Request) {
  const header = req.headers.get('authorization') ?? ''
  if (!header.startsWith('Bearer ')) return null
  const token = header.slice(7).trim(); if (!token) return null
  const response = await fetch(`${SUPABASE_URL}/auth/v1/user`, { headers:{ apikey:ANON_KEY, Authorization:`Bearer ${token}` } })
  if (!response.ok) return null
  const user = await response.json(); return typeof user?.id === 'string' ? user : null
}
function parseUuidOrNull(value: string | null) {
  if (!value) return null
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)) throw new ApiError(400,'Invalid id')
  return value
}

Deno.serve(async (req: Request) => {
  const requestId = crypto.randomUUID()
  try {
    if (req.method === 'OPTIONS') return new Response(null,{status:204,headers:corsHeaders(req)})
    const url = new URL(req.url)
    if (req.method === 'GET') {
      const resource = (url.searchParams.get('resource') ?? '').trim().toUpperCase()
      if (resource === 'ME') {
        const user = await authenticatedUser(req)
        if (!user) return respond(req,401,{error:'AUTH_REQUIRED',request_id:requestId})
        const member = await rpc('bullmatch_api_member',{p_user_id:user.id})
        return respond(req,200,{user:{id:user.id,email:user.email ?? null},membership:member,request_id:requestId})
      }
      if (!new Set(['DASHBOARD','BULLS','BULL','MATCHES','MATCH','VENUES']).has(resource)) throw new ApiError(400,'Unsupported public resource')
      const limitRaw=Number(url.searchParams.get('limit') ?? '50'), offsetRaw=Number(url.searchParams.get('offset') ?? '0')
      const data = await rpc('bullmatch_api_public_query',{
        p_resource:resource,
        p_id:parseUuidOrNull(url.searchParams.get('id')),
        p_search:url.searchParams.get('search'),
        p_limit:Number.isFinite(limitRaw)?Math.max(1,Math.min(Math.trunc(limitRaw),100)):50,
        p_offset:Number.isFinite(offsetRaw)?Math.max(0,Math.trunc(offsetRaw)):0,
      })
      return respond(req,200,{data,request_id:requestId},'public, max-age=30, s-maxage=60')
    }
    if (req.method === 'POST') {
      const length=Number(req.headers.get('content-length') ?? '0'); if (Number.isFinite(length)&&length>131072) throw new ApiError(413,'Request body too large')
      const user=await authenticatedUser(req); if(!user) return respond(req,401,{error:'AUTH_REQUIRED',request_id:requestId})
      const membership=await rpc('bullmatch_api_member',{p_user_id:user.id})
      if(!membership?.member||!membership?.active||membership?.role!=='ADMIN') return respond(req,403,{error:'ADMIN_REQUIRED',membership,request_id:requestId})
      let body: unknown; try { body=await req.json() } catch { throw new ApiError(400,'Invalid JSON body') }
      if(!body||typeof body!=='object'||Array.isArray(body)) throw new ApiError(400,'JSON object required')
      const operation=typeof (body as Record<string,unknown>).operation==='string'?String((body as Record<string,unknown>).operation).trim():''
      const payload=(body as Record<string,unknown>).payload
      if(!operation) throw new ApiError(400,'operation is required')
      if(payload!==undefined&&(payload===null||typeof payload!=='object'||Array.isArray(payload))) throw new ApiError(400,'payload must be an object')
      const result=await rpc('bullmatch_api_admin_command',{p_actor_id:user.id,p_operation:operation,p_payload:payload ?? {}})
      return respond(req,200,{data:result,request_id:requestId})
    }
    return respond(req,405,{error:'METHOD_NOT_ALLOWED',request_id:requestId})
  } catch(error) {
    const status=error instanceof ApiError?error.status:500
    const message=error instanceof Error?error.message:'Internal server error'
    if(status>=500) console.error({requestId,error})
    return respond(req,status,{error:status>=500?'INTERNAL_ERROR':'REQUEST_FAILED',message:status>=500?'Internal server error':message,request_id:requestId})
  }
})
