import { useEffect, useMemo, useState } from 'react'
import { type AuthSession, restoreSession, signInWithPassword, signOutLocal } from './auth'

type ViewId =
  | 'dashboard'
  | 'bulls'
  | 'bull-profile'
  | 'matches'
  | 'match-detail'
  | 'entry'
  | 'review'
  | 'settings'
  | 'login'

type IconName = 'home' | 'bull' | 'match' | 'plus' | 'review' | 'settings' | 'arrow' | 'search'

const allViews: ViewId[] = ['dashboard','bulls','bull-profile','matches','match-detail','entry','review','settings','login']
const mainViews: ViewId[] = ['dashboard', 'bulls', 'matches', 'entry', 'review']
const protectedViews = new Set<ViewId>(['entry', 'review'])

const navItems: Array<{ id: ViewId; label: string; icon: IconName }> = [
  { id: 'dashboard', label: 'ภาพรวม', icon: 'home' },
  { id: 'bulls', label: 'วัว', icon: 'bull' },
  { id: 'matches', label: 'คู่ชน', icon: 'match' },
  { id: 'entry', label: 'บันทึก', icon: 'plus' },
  { id: 'review', label: 'ตรวจสอบ', icon: 'review' },
]

function Icon({ name, size = 22 }: { name: IconName; size?: number }) {
  const common = {
    width: size,
    height: size,
    viewBox: '0 0 24 24',
    fill: 'none',
    stroke: 'currentColor',
    strokeWidth: 1.8,
    strokeLinecap: 'round' as const,
    strokeLinejoin: 'round' as const,
    'aria-hidden': true,
  }

  if (name === 'home') return <svg {...common}><path d="M3 11.5 12 4l9 7.5"/><path d="M5.5 10.5V20h13v-9.5"/><path d="M9.5 20v-6h5v6"/></svg>
  if (name === 'bull') return <svg {...common}><path d="M7 8c-2.2-.2-3.6-1.3-4-3 2.5-.4 4.5.2 5.5 1.8"/><path d="M17 8c2.2-.2 3.6-1.3 4-3-2.5-.4-4.5.2-5.5 1.8"/><path d="M7.5 7.5C8.6 6.5 10 6 12 6s3.4.5 4.5 1.5c1.1 1 1.5 2.5 1.5 4.2 0 4.6-2.3 7.3-6 7.3s-6-2.7-6-7.3c0-1.7.4-3.2 1.5-4.2Z"/><path d="M9 12h.01M15 12h.01"/><path d="M10 15.5c1.3.7 2.7.7 4 0"/></svg>
  if (name === 'match') return <svg {...common}><path d="M8 5h8"/><path d="M7 4h10v3c0 3.3-2.2 6-5 6s-5-2.7-5-6V4Z"/><path d="M12 13v4"/><path d="M8.5 20h7"/><path d="M10 17h4"/><path d="M5 6H3.5v1.5A3.5 3.5 0 0 0 7 11"/><path d="M19 6h1.5v1.5A3.5 3.5 0 0 1 17 11"/></svg>
  if (name === 'plus') return <svg {...common}><circle cx="12" cy="12" r="9"/><path d="M12 8v8M8 12h8"/></svg>
  if (name === 'review') return <svg {...common}><path d="M8 4h8"/><path d="M9 3h6v3H9z"/><path d="M6 5h12v16H6z"/><path d="m9 13 2 2 4-5"/></svg>
  if (name === 'settings') return <svg {...common}><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1l2-1.5-2-3.4-2.4 1a8 8 0 0 0-1.7-1L14.5 3h-5l-.4 3.1a8 8 0 0 0-1.7 1l-2.4-1-2 3.4L5 11a7 7 0 0 0 0 2l-2 1.5 2 3.4 2.4-1a8 8 0 0 0 1.7 1l.4 3.1h5l.4-3.1a8 8 0 0 0 1.7-1l2.4 1 2-3.4L19 13a7 7 0 0 0 0-1Z"/></svg>
  if (name === 'search') return <svg {...common}><circle cx="11" cy="11" r="6"/><path d="m16 16 4 4"/></svg>
  return <svg {...common}><path d="M5 12h14M14 7l5 5-5 5"/></svg>
}

function Brand() {
  return (
    <div className="brand">
      <div className="brand-mark"><Icon name="bull" size={27} /></div>
      <div><strong>BullMatch</strong><span>Intelligence</span></div>
    </div>
  )
}

function EmptyState({ title, body, action }: { title: string; body: string; action?: React.ReactNode }) {
  return (
    <div className="empty-state">
      <div className="empty-icon"><Icon name="bull" size={34} /></div>
      <h3>{title}</h3><p>{body}</p>{action}
    </div>
  )
}

function SectionTitle({ eyebrow, title, action }: { eyebrow?: string; title: string; action?: React.ReactNode }) {
  return (
    <div className="section-title">
      <div>{eyebrow && <span className="eyebrow">{eyebrow}</span>}<h2>{title}</h2></div>
      {action}
    </div>
  )
}

function Dashboard({ go }: { go: (view: ViewId) => void }) {
  const stats = [
    ['วัวในระบบ', '—', 'P1-007 พร้อมเชื่อม'],
    ['คู่ชนยืนยันแล้ว', '—', 'นับเฉพาะ VERIFIED + PUBLISHED'],
    ['สนาม', '—', 'รอ APP-003'],
    ['รอตรวจสอบ', '—', 'Review Queue'],
  ]
  return (
    <>
      <section className="hero-card">
        <div>
          <span className="eyebrow light">BULLMATCH INTELLIGENCE</span>
          <h1>ข้อมูลวัวชนที่ตรวจสอบย้อนกลับได้</h1>
          <p>รวมประวัติวัว คู่ชน ผลการแข่งขัน และหลักฐาน เพื่อให้สถิติอ้างอิงจากข้อมูลที่ผ่านการตรวจสอบ</p>
        </div>
        <div className="hero-badge"><span className="pulse-dot" />Auth + Stats Ready</div>
      </section>
      <div className="stat-grid">
        {stats.map(([label, value, note]) => <article className="stat-card" key={label}><span>{label}</span><strong>{value}</strong><small>{note}</small></article>)}
      </div>
      <SectionTitle eyebrow="ทางลัด" title="เริ่มงาน" />
      <div className="quick-grid">
        <button className="quick-card" onClick={() => go('entry')}><span className="quick-icon"><Icon name="plus" /></span><span><strong>บันทึกคู่ชน</strong><small>ต้องเข้าสู่ระบบ</small></span><Icon name="arrow" size={18} /></button>
        <button className="quick-card" onClick={() => go('bulls')}><span className="quick-icon"><Icon name="bull" /></span><span><strong>ทะเบียนวัว</strong><small>ค้นหาและดูประวัติวัว</small></span><Icon name="arrow" size={18} /></button>
        <button className="quick-card" onClick={() => go('review')}><span className="quick-icon"><Icon name="review" /></span><span><strong>Review Queue</strong><small>ต้องเข้าสู่ระบบ</small></span><Icon name="arrow" size={18} /></button>
      </div>
      <SectionTitle eyebrow="ข้อมูลล่าสุด" title="กิจกรรมของระบบ" />
      <div className="panel"><EmptyState title="รอเชื่อม API ข้อมูลจริง" body="P1-007 เตรียมสถิติแล้ว ขั้น APP-003 จะเชื่อม read API ที่ปลอดภัยเข้าหน้านี้" /></div>
    </>
  )
}

function Bulls({ go }: { go: (view: ViewId) => void }) {
  return (
    <>
      <SectionTitle eyebrow="ทะเบียนกลาง" title="วัวทั้งหมด" action={<button className="primary-button" disabled>เพิ่มวัว</button>} />
      <div className="toolbar">
        <label className="search-box"><Icon name="search" size={19} /><input placeholder="ค้นหาชื่อวัว คอก จังหวัด..." aria-label="ค้นหาวัว" /></label>
        <button className="filter-button">ตัวกรอง</button>
      </div>
      <div className="panel"><EmptyState title="ยังไม่มีข้อมูลวัวที่แสดงในหน้าแอป" body="ฐาน Production ยังไม่มีข้อมูลปลอม เมื่อ APP-003 เชื่อม API แล้ว วัวที่ VERIFIED จะปรากฏที่นี่" action={<button className="text-button" onClick={() => go('bull-profile')}>ดูโครงหน้ารายละเอียดวัว</button>} /></div>
    </>
  )
}

function BullProfile({ go }: { go: (view: ViewId) => void }) {
  return (
    <>
      <button className="back-button" onClick={() => go('bulls')}>← กลับทะเบียนวัว</button>
      <div className="profile-hero panel">
        <div className="profile-avatar"><Icon name="bull" size={48} /></div>
        <div className="profile-copy"><span className="status-chip neutral">ยังไม่ได้เลือกวัว</span><h2>รายละเอียดวัว</h2><p>P1-007 เตรียมสถิติ W/L/D, win rate, recent form และประวัติคู่ชนไว้แล้ว</p></div>
      </div>
      <div className="detail-grid">
        <div className="panel metric-panel"><span>จำนวนครั้งที่ชน</span><strong>—</strong><small>Published matches</small></div>
        <div className="panel metric-panel"><span>ชนะ</span><strong>—</strong><small>Win</small></div>
        <div className="panel metric-panel"><span>แพ้</span><strong>—</strong><small>Loss</small></div>
        <div className="panel metric-panel"><span>อัตราชนะ</span><strong>—</strong><small>W / (W+L+D)</small></div>
      </div>
      <SectionTitle title="ประวัติการแข่งขัน" eyebrow="MATCH HISTORY" />
      <div className="panel"><EmptyState title="ยังไม่มีวัวที่ถูกเลือก" body="หลัง APP-003 เชื่อมข้อมูล หน้านี้จะแสดง snapshot วันชน คู่ต่อสู้ สนาม ผล และ recent form" /></div>
    </>
  )
}

function Matches({ go }: { go: (view: ViewId) => void }) {
  return (
    <>
      <SectionTitle eyebrow="การแข่งขัน" title="คู่ชนและผลการแข่งขัน" action={<button className="primary-button" onClick={() => go('entry')}>บันทึกคู่ชน</button>} />
      <div className="segmented" role="tablist" aria-label="ตัวกรองการแข่งขัน"><button className="active">ทั้งหมด</button><button>ยืนยันแล้ว</button><button>รอตรวจ</button></div>
      <div className="panel"><EmptyState title="ยังไม่มีคู่ชนใน Production" body="หลังเชื่อม API หน้านี้จะแสดงวันที่ สนาม วัวทั้งสองฝั่ง ผล และสถานะ VERIFIED/PUBLISHED" action={<button className="text-button" onClick={() => go('match-detail')}>ดูโครงหน้ารายละเอียดคู่ชน</button>} /></div>
    </>
  )
}

function MatchDetail({ go }: { go: (view: ViewId) => void }) {
  return (
    <>
      <button className="back-button" onClick={() => go('matches')}>← กลับรายการคู่ชน</button>
      <div className="match-card panel">
        <div className="match-meta"><span className="status-chip neutral">ยังไม่ได้เลือกคู่ชน</span><span>สนาม —</span></div>
        <div className="versus">
          <div><div className="bull-circle"><Icon name="bull" size={34} /></div><strong>วัวฝั่ง A</strong><small>snapshot วันชน</small></div>
          <span className="vs-mark">VS</span>
          <div><div className="bull-circle"><Icon name="bull" size={34} /></div><strong>วัวฝั่ง B</strong><small>snapshot วันชน</small></div>
        </div>
        <div className="result-placeholder">ผลการแข่งขัน —</div>
      </div>
      <div className="detail-grid two">
        <div className="panel"><h3>ข้อมูลการแข่งขัน</h3><dl className="definition-list"><div><dt>วันที่</dt><dd>—</dd></div><div><dt>น้ำหนัก</dt><dd>— / —</dd></div><div><dt>ระยะเวลา</dt><dd>—</dd></div></dl></div>
        <div className="panel"><h3>การตรวจสอบ</h3><dl className="definition-list"><div><dt>สถานะ</dt><dd>—</dd></div><div><dt>หลักฐาน</dt><dd>—</dd></div><div><dt>เผยแพร่</dt><dd>—</dd></div></dl></div>
      </div>
    </>
  )
}

function ManualEntry({ session }: { session: AuthSession }) {
  return (
    <>
      <SectionTitle eyebrow="ADMIN WORKFLOW" title="บันทึกผลการแข่งขัน" />
      <div className="notice-card success"><strong>เข้าสู่ระบบแล้ว</strong><span>{session.user.email ?? session.user.id} • ยังต้องตรวจ BullMatch role ผ่าน API ใน APP-003 ก่อนอนุญาตให้บันทึกจริง</span></div>
      <div className="stepper" aria-label="ขั้นตอนบันทึกคู่ชน">
        {['งาน / สนาม', 'วัวทั้งสองฝั่ง', 'ผลการแข่งขัน', 'ตรวจและยืนยัน'].map((step, index) => <div className={index === 0 ? 'step active' : 'step'} key={step}><span>{index + 1}</span><small>{step}</small></div>)}
      </div>
      <form className="form-card panel" onSubmit={(event) => event.preventDefault()}>
        <div className="form-grid">
          <label><span>วันที่แข่งขัน</span><input type="date" /></label>
          <label><span>สนาม</span><input placeholder="เลือกสนาม" /></label>
          <label><span>วัวฝั่ง A</span><input placeholder="ค้นหาวัว" /></label>
          <label><span>วัวฝั่ง B</span><input placeholder="ค้นหาวัว" /></label>
          <label><span>น้ำหนักฝั่ง A (กก.)</span><input inputMode="decimal" placeholder="—" /></label>
          <label><span>น้ำหนักฝั่ง B (กก.)</span><input inputMode="decimal" placeholder="—" /></label>
          <label className="wide"><span>ผลการแข่งขัน</span><select defaultValue=""><option value="" disabled>เลือกผล</option><option>ฝั่ง A ชนะ</option><option>ฝั่ง B ชนะ</option><option>เสมอ</option><option>ไม่มีผล</option><option>ยกเลิก</option></select></label>
          <label className="wide"><span>หมายเหตุ</span><textarea rows={3} placeholder="รายละเอียดเพิ่มเติม (ถ้ามี)" /></label>
        </div>
        <div className="form-actions"><span>รอ APP-003 ตรวจ role และเชื่อม mutation API</span><button className="primary-button" disabled>บันทึกข้อมูล</button></div>
      </form>
    </>
  )
}

function ReviewQueue({ session }: { session: AuthSession }) {
  return (
    <>
      <SectionTitle eyebrow="HUMAN REVIEW" title="Review Queue" />
      <div className="notice-card success"><strong>Authenticated</strong><span>{session.user.email ?? session.user.id} • สิทธิ์ Reviewer/Admin จะตรวจฝั่ง API ในขั้นถัดไป</span></div>
      <div className="review-summary"><div><span>รายการรอตรวจ</span><strong>—</strong></div><div><span>ข้อมูลขัดแย้ง</span><strong>—</strong></div><div><span>อาจเป็นวัวตัวเดียวกัน</span><strong>—</strong></div></div>
      <div className="segmented"><button className="active">ทั้งหมด</button><button>ความขัดแย้ง</button><button>ชื่อซ้ำ</button></div>
      <div className="panel"><EmptyState title="ยังไม่เชื่อม Review API" body="APP-003/P1-008 จะเชื่อมรายการพร้อมหลักฐานและคำสั่งตาม role โดยไม่เปิด private schema ให้ browser" /></div>
    </>
  )
}

function Login({ onSignedIn, go }: { onSignedIn: (session: AuthSession) => void; go: (view: ViewId) => void }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const submit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setError(null)
    if (!email.trim() || !password) {
      setError('กรุณากรอกอีเมลและรหัสผ่าน')
      return
    }
    setPending(true)
    try {
      onSignedIn(await signInWithPassword(email, password))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'เข้าสู่ระบบไม่สำเร็จ')
    } finally {
      setPending(false)
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-card panel">
        <div className="auth-brand"><div className="profile-avatar"><Icon name="bull" size={42} /></div><div><span className="eyebrow">SECURE ACCESS</span><h2>เข้าสู่ระบบ BullMatch</h2></div></div>
        <p className="auth-intro">สำหรับ Admin / Reviewer / Viewer ที่มีบัญชี Supabase Auth แล้วเท่านั้น ระบบไม่มีปุ่มสมัครสมาชิกสาธารณะ</p>
        <form className="auth-form" onSubmit={submit}>
          <label><span>อีเมล</span><input type="email" autoComplete="username" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="name@example.com" /></label>
          <label><span>รหัสผ่าน</span><input type="password" autoComplete="current-password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="••••••••" /></label>
          {error && <div className="auth-error" role="alert">{error}</div>}
          <button className="primary-button auth-submit" type="submit" disabled={pending}>{pending ? 'กำลังเข้าสู่ระบบ…' : 'เข้าสู่ระบบ'}</button>
        </form>
        <div className="auth-note">การเข้าสู่ระบบยืนยันตัวตนเท่านั้น สิทธิ์ ADMIN/REVIEWER/VIEWER จะตรวจจาก `bullmatch.app_users` ผ่าน API ฝั่ง server ใน APP-003</div>
        <button className="text-button" onClick={() => go('dashboard')}>กลับหน้าสาธารณะ</button>
      </div>
    </div>
  )
}

function Settings({ session, authLoading, onLogin, onLogout }: { session: AuthSession | null; authLoading: boolean; onLogin: () => void; onLogout: () => Promise<void> }) {
  return (
    <>
      <SectionTitle eyebrow="ระบบ" title="โปรไฟล์และการตั้งค่า" />
      <div className="panel settings-list">
        <div><span>บัญชีผู้ใช้</span><strong>{authLoading ? 'กำลังตรวจ session…' : session?.user.email ?? 'ยังไม่ได้เข้าสู่ระบบ'}</strong></div>
        <div><span>Supabase Auth</span><strong>{session ? 'SIGNED IN' : 'SIGNED OUT'}</strong></div>
        <div><span>บทบาท BullMatch</span><strong>{session ? 'รอตรวจผ่าน APP-003 API' : '—'}</strong></div>
        <div><span>Data API</span><strong>Domain schema ไม่เปิดตรงสู่ browser</strong></div>
      </div>
      <div className="settings-actions">
        {session ? <button className="secondary-button" onClick={() => void onLogout()}>ออกจากระบบ</button> : <button className="primary-button" onClick={onLogin}>เข้าสู่ระบบ</button>}
      </div>
    </>
  )
}

function AuthLoading() {
  return <div className="panel"><EmptyState title="กำลังตรวจสอบการเข้าสู่ระบบ" body="กำลังตรวจ session กับ Supabase Auth…" /></div>
}

function App() {
  const initialView = useMemo<ViewId>(() => {
    const hash = window.location.hash.replace('#/', '').replace('#', '') as ViewId
    return hash && allViews.includes(hash) ? hash : 'dashboard'
  }, [])
  const [view, setView] = useState<ViewId>(initialView)
  const [session, setSession] = useState<AuthSession | null>(null)
  const [authLoading, setAuthLoading] = useState(true)
  const [returnAfterLogin, setReturnAfterLogin] = useState<ViewId | null>(null)

  const setLocation = (next: ViewId) => {
    setView(next)
    window.location.hash = `/${next}`
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  useEffect(() => {
    let active = true
    restoreSession().then((restored) => {
      if (!active) return
      setSession(restored)
      setAuthLoading(false)
      const hash = window.location.hash.replace('#/', '').replace('#', '') as ViewId
      if (!restored && protectedViews.has(hash)) {
        setReturnAfterLogin(hash)
        setLocation('login')
      }
    })
    return () => { active = false }
  }, [])

  useEffect(() => {
    const onHash = () => {
      const next = window.location.hash.replace('#/', '').replace('#', '') as ViewId
      if (!allViews.includes(next)) return
      if (!authLoading && !session && protectedViews.has(next)) {
        setReturnAfterLogin(next)
        setView('login')
        if (window.location.hash !== '#/login') window.location.hash = '/login'
        return
      }
      setView(next)
    }
    window.addEventListener('hashchange', onHash)
    return () => window.removeEventListener('hashchange', onHash)
  }, [authLoading, session])

  const go = (next: ViewId) => {
    if (protectedViews.has(next) && !session) {
      setReturnAfterLogin(next)
      setLocation('login')
      return
    }
    setLocation(next)
  }

  const handleSignedIn = (nextSession: AuthSession) => {
    setSession(nextSession)
    const target = returnAfterLogin ?? 'settings'
    setReturnAfterLogin(null)
    setLocation(target)
  }

  const handleLogout = async () => {
    const current = session
    setSession(null)
    await signOutLocal(current)
    if (protectedViews.has(view)) setLocation('dashboard')
  }

  const activeMain = mainViews.includes(view) ? view : view === 'bull-profile' ? 'bulls' : view === 'match-detail' ? 'matches' : 'dashboard'

  let content: React.ReactNode
  if (authLoading && protectedViews.has(view)) content = <AuthLoading />
  else if (view === 'dashboard') content = <Dashboard go={go} />
  else if (view === 'bulls') content = <Bulls go={go} />
  else if (view === 'bull-profile') content = <BullProfile go={go} />
  else if (view === 'matches') content = <Matches go={go} />
  else if (view === 'match-detail') content = <MatchDetail go={go} />
  else if (view === 'entry' && session) content = <ManualEntry session={session} />
  else if (view === 'review' && session) content = <ReviewQueue session={session} />
  else if (view === 'login') content = session ? <Settings session={session} authLoading={false} onLogin={() => go('login')} onLogout={handleLogout} /> : <Login onSignedIn={handleSignedIn} go={go} />
  else content = <Settings session={session} authLoading={authLoading} onLogin={() => go('login')} onLogout={handleLogout} />

  const userLabel = session?.user.email?.trim().charAt(0).toUpperCase() || (session ? '✓' : 'เข้า')

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <Brand />
        <nav className="side-nav" aria-label="เมนูหลัก">
          {navItems.map((item) => <button key={item.id} className={activeMain === item.id ? 'active' : ''} onClick={() => go(item.id)}><Icon name={item.icon} /><span>{item.label}</span></button>)}
        </nav>
        <button className={view === 'settings' || view === 'login' ? 'settings-button active' : 'settings-button'} onClick={() => go('settings')}><Icon name="settings" /><span>การตั้งค่า</span></button>
      </aside>

      <div className="app-body">
        <header className="topbar">
          <div className="mobile-brand"><Brand /></div>
          <div className="topbar-copy"><span>ฐานข้อมูลกีฬาวัวชน</span><strong>{session ? `เข้าสู่ระบบ: ${session.user.email ?? 'ผู้ใช้'}` : 'Public mode • Verified sports intelligence'}</strong></div>
          <button className={session ? 'user-button signed-in' : 'user-button'} onClick={() => go(session ? 'settings' : 'login')} aria-label={session ? 'เปิดโปรไฟล์ผู้ใช้' : 'เข้าสู่ระบบ'} title={session?.user.email ?? 'เข้าสู่ระบบ'}>{userLabel}</button>
        </header>
        <main>{content}</main>
      </div>

      <nav className="bottom-nav" aria-label="เมนูมือถือ">
        {navItems.map((item) => <button key={item.id} className={activeMain === item.id ? 'active' : ''} onClick={() => go(item.id)}><Icon name={item.icon} size={21} /><span>{item.label}</span></button>)}
      </nav>
    </div>
  )
}

export default App
