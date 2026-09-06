import { useEffect, useMemo, useState } from 'react'
import type { AuthSession } from './auth'
import { SUPABASE_PUBLISHABLE_KEY, SUPABASE_URL } from './auth'
import type { MeData } from './api'
import './review-queue.css'

const API_URL = `${SUPABASE_URL}/functions/v1/bullmatch-api`

type JsonMap = Record<string, unknown>

type ReviewQueueItem = {
  id: string
  case_type: string
  status: string
  priority: string
  priority_rank: number
  subject_type: string
  subject_ref: JsonMap | null
  summary: string | null
  context: JsonMap | null
  assigned_to: string | null
  assigned_display_name: string | null
  case_version: number
  created_at: string
  updated_at: string
  claim_count: number
  evidence_link_count: number
  has_conflict: boolean
  risk_tier: string
}

type ReviewClaim = {
  id: string
  claim_role: string
  subject_type: string
  subject_ref: JsonMap | null
  field_key: string
  value_json: unknown
  basis: string
  confidence: number | null
  status: string
  created_at: string
  evidence_count: number
}

type ReviewEvidence = {
  id: string
  claim_id: string
  relationship: string
  evidence_type: string
  access_class: string
  storage_ref: string | null
  text_excerpt: string | null
  timestamp_start_seconds: number | null
  timestamp_end_seconds: number | null
  content_sha256: string | null
  source: {
    id: string
    title: string | null
    canonical_url: string | null
    published_at: string | null
    retrieved_at: string | null
    source_name: string | null
    reliability_tier: string | null
  }
}

type ReviewHistory = {
  id: string
  actor_id: string
  actor_display_name: string | null
  action: string
  command_id: string
  expected_case_version: number
  case_version_before: number
  case_version_after: number
  notes: string | null
  created_at: string
}

type ReviewCaseDetail = {
  case: {
    id: string
    case_type: string
    status: string
    priority: string
    subject_type: string
    subject_ref: JsonMap | null
    summary: string | null
    context: JsonMap | null
    assigned_to: string | null
    assigned_display_name: string | null
    case_version: number
    created_at: string
    updated_at: string
    resolved_at: string | null
    resolved_by: string | null
  }
  claims: ReviewClaim[]
  evidence: ReviewEvidence[]
  entity_match_candidates: JsonMap[]
  duplicate_candidates: JsonMap[]
  history: ReviewHistory[]
}

type ApiEnvelope<T> = { data: T; request_id: string }

type IdentityPreview = JsonMap & {
  execution_enabled?: boolean
  impact_preview_fingerprint?: string
  warnings?: unknown[]
}

function fmtDateTime(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Intl.DateTimeFormat('th-TH', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value))
  } catch {
    return value
  }
}

function compactJson(value: unknown) {
  if (value == null) return '—'
  if (typeof value === 'string') return value
  try {
    const text = JSON.stringify(value)
    return text.length > 220 ? `${text.slice(0, 217)}…` : text
  } catch {
    return String(value)
  }
}

function safeHttpUrl(value: string | null | undefined) {
  if (!value) return null
  try {
    const url = new URL(value)
    return url.protocol === 'https:' || url.protocol === 'http:' ? url.href : null
  } catch {
    return null
  }
}

async function readError(response: Response) {
  try {
    const body = await response.json() as Record<string, unknown>
    const message = body.message ?? body.error
    if (typeof message === 'string' && message.trim()) return message
  } catch {
    // Fall through to status-based message.
  }
  return `BullMatch Review API ตอบกลับด้วยสถานะ ${response.status}`
}

async function reviewGet<T>(session: AuthSession, resource: string, id?: string): Promise<T> {
  const url = new URL(API_URL)
  url.searchParams.set('resource', resource)
  if (id) url.searchParams.set('id', id)
  const response = await fetch(url, {
    headers: {
      apikey: SUPABASE_PUBLISHABLE_KEY,
      Authorization: `Bearer ${session.access_token}`,
    },
  })
  if (!response.ok) throw new Error(await readError(response))
  return ((await response.json()) as ApiEnvelope<T>).data
}

async function reviewCommand(
  session: AuthSession,
  detail: ReviewCaseDetail,
  action: 'CLAIM' | 'UNCLAIM' | 'COMMENT' | 'APPROVE' | 'REJECT',
  note: string,
) {
  const payload: JsonMap = {}
  if (action === 'APPROVE' || action === 'REJECT') payload.claim_ids = detail.claims.map(claim => claim.id)
  const command = {
    schema_version: '1.0.0',
    command_id: crypto.randomUUID(),
    review_case_id: detail.case.id,
    action,
    expected_case_status: detail.case.status,
    expected_case_version: detail.case.case_version,
    note: note.trim() || undefined,
    payload,
  }
  const response = await fetch(API_URL, {
    method: 'POST',
    headers: {
      apikey: SUPABASE_PUBLISHABLE_KEY,
      Authorization: `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ operation: 'review_command', payload: command }),
  })
  if (!response.ok) throw new Error(await readError(response))
  return ((await response.json()) as ApiEnvelope<JsonMap>).data
}

function StatusPill({ children, tone = 'neutral' }: { children: React.ReactNode; tone?: 'neutral' | 'danger' | 'verified' | 'warning' }) {
  return <span className={`review-pill ${tone}`}>{children}</span>
}

export default function ReviewQueuePanel({ session, me }: { session: AuthSession; me: MeData | null }) {
  const allowed = Boolean(me?.membership.active && ['ADMIN', 'REVIEWER'].includes(me.membership.role ?? ''))
  const [queue, setQueue] = useState<ReviewQueueItem[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [detail, setDetail] = useState<ReviewCaseDetail | null>(null)
  const [preview, setPreview] = useState<IdentityPreview | null>(null)
  const [loadingQueue, setLoadingQueue] = useState(false)
  const [loadingDetail, setLoadingDetail] = useState(false)
  const [pendingAction, setPendingAction] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [note, setNote] = useState('')
  const [refreshTick, setRefreshTick] = useState(0)

  const selectedQueueItem = useMemo(() => queue.find(item => item.id === selectedId) ?? null, [queue, selectedId])

  useEffect(() => {
    if (!allowed) return
    let active = true
    setLoadingQueue(true)
    setError(null)
    reviewGet<ReviewQueueItem[]>(session, 'REVIEW_QUEUE')
      .then(items => {
        if (!active) return
        setQueue(items)
        setSelectedId(current => current && items.some(item => item.id === current) ? current : items[0]?.id ?? null)
      })
      .catch(err => { if (active) setError(err instanceof Error ? err.message : 'โหลด Review Queue ไม่สำเร็จ') })
      .finally(() => { if (active) setLoadingQueue(false) })
    return () => { active = false }
  }, [allowed, session, refreshTick])

  useEffect(() => {
    if (!allowed || !selectedId) {
      setDetail(null)
      setPreview(null)
      return
    }
    let active = true
    setLoadingDetail(true)
    setError(null)
    setPreview(null)
    reviewGet<ReviewCaseDetail>(session, 'REVIEW_CASE', selectedId)
      .then(value => { if (active) setDetail(value) })
      .catch(err => { if (active) setError(err instanceof Error ? err.message : 'โหลด Review Case ไม่สำเร็จ') })
      .finally(() => { if (active) setLoadingDetail(false) })
    return () => { active = false }
  }, [allowed, selectedId, session, refreshTick])

  async function runAction(action: 'CLAIM' | 'UNCLAIM' | 'COMMENT' | 'APPROVE' | 'REJECT') {
    if (!detail || pendingAction) return
    const trimmed = note.trim()
    if ((action === 'COMMENT' || action === 'APPROVE' || action === 'REJECT') && !trimmed) {
      setError('กรุณาใส่บันทึกผู้ตรวจสอบก่อนดำเนินการ เพื่อให้การตัดสินใจมีบริบทใน audit trail')
      return
    }
    if ((action === 'APPROVE' || action === 'REJECT') && detail.claims.length === 0) {
      setError('เคสนี้ไม่มี atomic claim ที่สามารถตัดสินใจได้')
      return
    }
    setPendingAction(action)
    setError(null)
    try {
      await reviewCommand(session, detail, action, trimmed)
      setNote('')
      setRefreshTick(value => value + 1)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Review command ไม่สำเร็จ')
    } finally {
      setPendingAction(null)
    }
  }

  async function loadIdentityPreview() {
    if (!detail || pendingAction) return
    setPendingAction('PREVIEW')
    setError(null)
    try {
      setPreview(await reviewGet<IdentityPreview>(session, 'IDENTITY_IMPACT_PREVIEW', detail.case.id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'โหลด Identity Impact Preview ไม่สำเร็จ')
    } finally {
      setPendingAction(null)
    }
  }

  if (!allowed) {
    return <><div className="section-title"><div><span className="eyebrow">HUMAN REVIEW</span><h2>Review Queue</h2></div></div><div className="panel review-access-denied"><h3>ไม่มีสิทธิ์ Review</h3><p>ต้องเป็น ACTIVE ADMIN หรือ REVIEWER โดยสิทธิ์ถูกตรวจซ้ำที่ Edge Function และฐานข้อมูล</p></div></>
  }

  const canClaim = detail?.case.status === 'OPEN' && !detail.case.assigned_to
  const canUnclaim = detail?.case.status === 'IN_REVIEW' && Boolean(detail.case.assigned_to) && (detail.case.assigned_to === me?.user.id || me?.membership.role === 'ADMIN')
  const canDecide = Boolean(detail && ['OPEN', 'IN_REVIEW'].includes(detail.case.status) && detail.claims.length > 0)

  return <>
    <div className="section-title review-heading"><div><span className="eyebrow">HUMAN REVIEW</span><h2>Evidence Review Control Room</h2><p>ตรวจหลักฐานและ atomic claims โดยไม่เขียนทับ canonical history โดยตรง</p></div><button className="secondary-button" onClick={() => setRefreshTick(value => value + 1)} disabled={loadingQueue || Boolean(pendingAction)}>รีเฟรช</button></div>
    <div className="notice-card success"><strong>{me?.membership.role}</strong><span>สิทธิ์ reviewer ยืนยันจาก Production API แล้ว • การตัดสินใจทุกคำสั่งใช้ optimistic case version + idempotent command ID</span></div>
    <div className="review-boundary"><strong>Canonical truth boundary</strong><span>APPROVE = ยืนยัน atomic claim เท่านั้น ไม่ใช่การเผยแพร่หรือแก้ประวัติวัว/คู่ชนโดยตรง การ promote canonical fact เป็นคำสั่งแยกที่มี policy และ provenance gate</span></div>
    {error && <div className="review-error" role="alert"><strong>Review API</strong><span>{error}</span></div>}
    <div className="review-workspace">
      <aside className="review-queue-panel panel" aria-label="Review Queue">
        <div className="review-panel-header"><div><span className="eyebrow">QUEUE</span><h3>เคสที่ต้องตรวจ</h3></div><strong>{loadingQueue ? '…' : queue.length}</strong></div>
        {loadingQueue ? <p className="review-muted">กำลังโหลดคิวจาก Production…</p> : queue.length === 0 ? <div className="review-empty"><strong>ยังไม่มี Review Case</strong><span>ระบบไม่สร้างข้อมูลตัวอย่าง เคสจะปรากฏเมื่อมี contribution/evidence จริงเข้าสู่ review workflow</span></div> : <div className="review-queue-list">{queue.map(item => <button key={item.id} className={item.id === selectedId ? 'review-case-row active' : 'review-case-row'} onClick={() => setSelectedId(item.id)}><div className="review-case-top"><StatusPill tone={item.priority === 'URGENT' || item.priority === 'HIGH' ? 'warning' : 'neutral'}>{item.priority}</StatusPill>{item.has_conflict && <StatusPill tone="danger">CONFLICT</StatusPill>}<span>v{item.case_version}</span></div><strong>{item.summary || `${item.subject_type} • ${item.case_type}`}</strong><small>{item.case_type} • {item.risk_tier}</small><div className="review-case-counts"><span>{item.claim_count} claims</span><span>{item.evidence_link_count} evidence</span><span>{item.assigned_display_name || (item.assigned_to ? 'Assigned' : 'Unassigned')}</span></div></button>)}</div>}
      </aside>

      <section className="review-detail-panel">
        {!selectedId ? <div className="panel review-empty large"><strong>เลือก Review Case</strong><span>เลือกเคสจากคิวเพื่อดู claims, evidence, candidate signals และ audit history</span></div> : loadingDetail ? <div className="panel review-empty large"><strong>กำลังโหลดเคส</strong><span>อ่านข้อมูลผ่าน reviewer-only API boundary…</span></div> : !detail ? <div className="panel review-empty large"><strong>ไม่พบ Review Case</strong><span>เคสอาจถูกแก้ไขหรือปิดโดย reviewer อื่น กรุณารีเฟรชคิว</span></div> : <>
          <div className="review-case-hero panel">
            <div className="review-case-hero-top"><div><span className="eyebrow">{detail.case.subject_type} / {detail.case.case_type}</span><h3>{detail.case.summary || 'Review Case'}</h3></div><div className="review-status-stack"><StatusPill tone={detail.case.status === 'RESOLVED' ? 'verified' : 'neutral'}>{detail.case.status}</StatusPill><StatusPill tone={detail.case.priority === 'URGENT' || detail.case.priority === 'HIGH' ? 'warning' : 'neutral'}>{detail.case.priority}</StatusPill></div></div>
            <div className="review-meta-grid"><span><b>Case version</b>v{detail.case.case_version}</span><span><b>Assigned</b>{detail.case.assigned_display_name || detail.case.assigned_to || 'ยังไม่มีผู้รับเคส'}</span><span><b>Updated</b>{fmtDateTime(detail.case.updated_at)}</span><span><b>Subject ref</b>{compactJson(detail.case.subject_ref)}</span></div>
          </div>

          <div className="review-action-bar panel">
            <label><span>Reviewer note / เหตุผล</span><textarea value={note} onChange={event => setNote(event.target.value)} placeholder="บันทึกสิ่งที่ตรวจพบ แหล่งหลักฐาน หรือเหตุผลในการตัดสินใจ…" rows={3}/></label>
            <div className="review-actions">
              {canClaim && <button className="secondary-button" disabled={Boolean(pendingAction)} onClick={() => void runAction('CLAIM')}>{pendingAction === 'CLAIM' ? 'กำลังรับเคส…' : 'รับเคส'}</button>}
              {canUnclaim && <button className="secondary-button" disabled={Boolean(pendingAction)} onClick={() => void runAction('UNCLAIM')}>{pendingAction === 'UNCLAIM' ? 'กำลังคืนเคส…' : 'คืนเคส'}</button>}
              <button className="secondary-button" disabled={Boolean(pendingAction) || !note.trim()} onClick={() => void runAction('COMMENT')}>{pendingAction === 'COMMENT' ? 'กำลังบันทึก…' : 'เพิ่มบันทึก'}</button>
              {canDecide && <button className="review-reject-button" disabled={Boolean(pendingAction) || !note.trim()} onClick={() => void runAction('REJECT')}>{pendingAction === 'REJECT' ? 'กำลังปฏิเสธ…' : 'Reject claims'}</button>}
              {canDecide && <button className="primary-button" disabled={Boolean(pendingAction) || !note.trim()} onClick={() => void runAction('APPROVE')}>{pendingAction === 'APPROVE' ? 'กำลังยืนยัน…' : 'Verify claims'}</button>}
            </div>
          </div>

          {detail.case.case_type === 'MERGE_SPLIT' && <div className="review-identity-preview panel"><div><span className="eyebrow">IDENTITY SAFETY</span><h3>Bull identity impact preview</h3><p>อ่านผลกระทบเท่านั้น ปุ่ม merge/split execution ถูกปิดตามนโยบายปัจจุบัน</p></div><button className="secondary-button" disabled={Boolean(pendingAction)} onClick={() => void loadIdentityPreview()}>{pendingAction === 'PREVIEW' ? 'กำลังคำนวณ…' : 'โหลด Impact Preview'}</button>{preview && <div className="review-preview-result"><StatusPill tone={preview.execution_enabled === false ? 'warning' : 'neutral'}>EXECUTION {preview.execution_enabled === false ? 'DISABLED' : 'UNSPECIFIED'}</StatusPill><code>{compactJson(preview)}</code></div>}</div>}

          <div className="review-section-title"><span className="eyebrow">ATOMIC CLAIMS</span><h3>Claims ที่ต้องตัดสินใจ</h3><span>{detail.claims.length}</span></div>
          {detail.claims.length === 0 ? <div className="panel review-empty"><strong>ไม่มี claim ในเคสนี้</strong><span>ใช้เฉพาะคำสั่งที่เหมาะกับประเภทเคส ห้ามสร้าง canonical mutation จากข้อมูลที่ไม่มี claim/evidence รองรับ</span></div> : <div className="review-claims">{detail.claims.map(claim => <article className="panel review-claim-card" key={claim.id}><div className="review-claim-head"><div><StatusPill>{claim.claim_role}</StatusPill><StatusPill tone={claim.status === 'CONFLICT' ? 'danger' : claim.status === 'VERIFIED' ? 'verified' : 'neutral'}>{claim.status}</StatusPill></div><span>{claim.evidence_count} evidence</span></div><h4>{claim.field_key}</h4><div className="review-claim-value">{compactJson(claim.value_json)}</div><dl><div><dt>Subject</dt><dd>{claim.subject_type}</dd></div><div><dt>Basis</dt><dd>{claim.basis}</dd></div><div><dt>Confidence signal</dt><dd>{claim.confidence == null ? 'ไม่ได้ระบุ' : String(claim.confidence)}</dd></div></dl></article>)}</div>}

          <div className="review-section-title"><span className="eyebrow">EVIDENCE</span><h3>หลักฐานที่เชื่อมกับ claims</h3><span>{detail.evidence.length}</span></div>
          {detail.evidence.length === 0 ? <div className="panel review-empty"><strong>ยังไม่มี evidence link</strong><span>ไม่ควรยืนยันข้อเท็จจริงสำคัญหากไม่มีหลักฐานที่เหมาะสมตาม policy</span></div> : <div className="review-evidence-list">{detail.evidence.map(item => { const href = safeHttpUrl(item.source.canonical_url); return <article className="panel review-evidence-card" key={`${item.id}-${item.claim_id}`}><div className="review-evidence-head"><StatusPill tone={item.relationship === 'CONTRADICTS' ? 'danger' : item.relationship === 'SUPPORTS' ? 'verified' : 'neutral'}>{item.relationship}</StatusPill><StatusPill>{item.access_class}</StatusPill><span>{item.evidence_type}</span></div><strong>{item.source.title || item.source.source_name || 'Evidence source'}</strong><p>{item.text_excerpt || (item.access_class === 'RESTRICTED' ? 'เนื้อหาถูกจำกัดตาม evidence access policy' : 'ไม่มีข้อความ excerpt')}</p><div className="review-evidence-meta"><span>Source tier: {item.source.reliability_tier || '—'}</span><span>Retrieved: {fmtDateTime(item.source.retrieved_at)}</span>{href && <a href={href} target="_blank" rel="noreferrer">เปิดแหล่งอ้างอิง</a>}</div></article> })}</div>}

          {(detail.entity_match_candidates.length > 0 || detail.duplicate_candidates.length > 0) && <><div className="review-section-title"><span className="eyebrow">IDENTITY / DUPLICATE SIGNALS</span><h3>Candidate signals</h3><span>{detail.entity_match_candidates.length + detail.duplicate_candidates.length}</span></div><div className="review-candidate-grid">{detail.entity_match_candidates.map((candidate, index) => <article className="panel" key={`entity-${index}`}><strong>Entity match candidate</strong><code>{compactJson(candidate)}</code></article>)}{detail.duplicate_candidates.map((candidate, index) => <article className="panel" key={`duplicate-${index}`}><strong>Duplicate candidate</strong><code>{compactJson(candidate)}</code></article>)}</div></>}

          <div className="review-section-title"><span className="eyebrow">AUDIT TRAIL</span><h3>ประวัติการตรวจ</h3><span>{detail.history.length}</span></div>
          {detail.history.length === 0 ? <div className="panel review-empty"><strong>ยังไม่มี review action</strong><span>การตัดสินใจใหม่จะถูกบันทึกแบบ append-only พร้อม command ID และ case version</span></div> : <div className="review-history">{[...detail.history].reverse().map(row => <article className="review-history-row" key={row.id}><div><StatusPill>{row.action}</StatusPill><strong>{row.actor_display_name || row.actor_id}</strong></div><p>{row.notes || 'ไม่มีบันทึกเพิ่มเติม'}</p><small>{fmtDateTime(row.created_at)} • v{row.case_version_before} → v{row.case_version_after}</small></article>)}</div>}
        </>}
      </section>
    </div>
    {selectedQueueItem && <p className="review-footnote">Selected: {selectedQueueItem.id} • UI นี้ไม่เปิด destructive MERGE/SPLIT หรือ broad canonical EDIT</p>}
  </>
}
