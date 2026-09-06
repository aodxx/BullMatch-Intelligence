import { useEffect, useMemo, useState } from 'react'

type ViewId =
  | 'dashboard'
  | 'bulls'
  | 'bull-profile'
  | 'matches'
  | 'match-detail'
  | 'entry'
  | 'review'
  | 'settings'

type IconName = 'home' | 'bull' | 'match' | 'plus' | 'review' | 'settings' | 'arrow' | 'search'

const mainViews: ViewId[] = ['dashboard', 'bulls', 'matches', 'entry', 'review']

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

  if (name === 'home') {
    return <svg {...common}><path d="M3 11.5 12 4l9 7.5"/><path d="M5.5 10.5V20h13v-9.5"/><path d="M9.5 20v-6h5v6"/></svg>
  }
  if (name === 'bull') {
    return <svg {...common}><path d="M7 8c-2.2-.2-3.6-1.3-4-3 2.5-.4 4.5.2 5.5 1.8"/><path d="M17 8c2.2-.2 3.6-1.3 4-3-2.5-.4-4.5.2-5.5 1.8"/><path d="M7.5 7.5C8.6 6.5 10 6 12 6s3.4.5 4.5 1.5c1.1 1 1.5 2.5 1.5 4.2 0 4.6-2.3 7.3-6 7.3s-6-2.7-6-7.3c0-1.7.4-3.2 1.5-4.2Z"/><path d="M9 12h.01M15 12h.01"/><path d="M10 15.5c1.3.7 2.7.7 4 0"/></svg>
  }
  if (name === 'match') {
    return <svg {...common}><path d="M8 5h8"/><path d="M7 4h10v3c0 3.3-2.2 6-5 6s-5-2.7-5-6V4Z"/><path d="M12 13v4"/><path d="M8.5 20h7"/><path d="M10 17h4"/><path d="M5 6H3.5v1.5A3.5 3.5 0 0 0 7 11"/><path d="M19 6h1.5v1.5A3.5 3.5 0 0 1 17 11"/></svg>
  }
  if (name === 'plus') {
    return <svg {...common}><circle cx="12" cy="12" r="9"/><path d="M12 8v8M8 12h8"/></svg>
  }
  if (name === 'review') {
    return <svg {...common}><path d="M8 4h8"/><path d="M9 3h6v3H9z"/><path d="M6 5h12v16H6z"/><path d="m9 13 2 2 4-5"/></svg>
  }
  if (name === 'settings') {
    return <svg {...common}><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1l2-1.5-2-3.4-2.4 1a8 8 0 0 0-1.7-1L14.5 3h-5l-.4 3.1a8 8 0 0 0-1.7 1l-2.4-1-2 3.4L5 11a7 7 0 0 0 0 2l-2 1.5 2 3.4 2.4-1a8 8 0 0 0 1.7 1l.4 3.1h5l.4-3.1a8 8 0 0 0 1.7-1l2.4 1 2-3.4L19 13a7 7 0 0 0 0-1Z"/></svg>
  }
  if (name === 'search') {
    return <svg {...common}><circle cx="11" cy="11" r="6"/><path d="m16 16 4 4"/></svg>
  }
  return <svg {...common}><path d="M5 12h14M14 7l5 5-5 5"/></svg>
}

function Brand() {
  return (
    <div className="brand">
      <div className="brand-mark"><Icon name="bull" size={27} /></div>
      <div>
        <strong>BullMatch</strong>
        <span>Intelligence</span>
      </div>
    </div>
  )
}

function EmptyState({ title, body, action }: { title: string; body: string; action?: React.ReactNode }) {
  return (
    <div className="empty-state">
      <div className="empty-icon"><Icon name="bull" size={34} /></div>
      <h3>{title}</h3>
      <p>{body}</p>
      {action}
    </div>
  )
}

function SectionTitle({ eyebrow, title, action }: { eyebrow?: string; title: string; action?: React.ReactNode }) {
  return (
    <div className="section-title">
      <div>
        {eyebrow && <span className="eyebrow">{eyebrow}</span>}
        <h2>{title}</h2>
      </div>
      {action}
    </div>
  )
}

function Dashboard({ go }: { go: (view: ViewId) => void }) {
  const stats = [
    ['วัวในระบบ', '—', 'รอเชื่อมข้อมูลจริง'],
    ['คู่ชนยืนยันแล้ว', '—', 'นับเฉพาะ VERIFIED'],
    ['สนาม', '—', 'รอเชื่อมข้อมูลจริง'],
    ['รอตรวจสอบ', '—', 'Review Queue'],
  ]

  return (
    <>
      <section className="hero-card">
        <div>
          <span className="eyebrow light">BULLMATCH INTELLIGENCE</span>
          <h1>ข้อมูลวัวชนที่ตรวจสอบย้อนกลับได้</h1>
          <p>รวมประวัติวัว คู่ชน ผลการแข่งขัน และหลักฐาน เพื่อให้สถิติในอนาคตอ้างอิงจากข้อมูลที่ผ่านการตรวจสอบ</p>
        </div>
        <div className="hero-badge">
          <span className="pulse-dot" />
          UI Foundation
        </div>
      </section>

      <div className="stat-grid">
        {stats.map(([label, value, note]) => (
          <article className="stat-card" key={label}>
            <span>{label}</span>
            <strong>{value}</strong>
            <small>{note}</small>
          </article>
        ))}
      </div>

      <SectionTitle eyebrow="ทางลัด" title="เริ่มงาน" />
      <div className="quick-grid">
        <button className="quick-card" onClick={() => go('entry')}>
          <span className="quick-icon"><Icon name="plus" /></span>
          <span><strong>บันทึกคู่ชน</strong><small>โครงแบบฟอร์ม Manual Entry</small></span>
          <Icon name="arrow" size={18} />
        </button>
        <button className="quick-card" onClick={() => go('bulls')}>
          <span className="quick-icon"><Icon name="bull" /></span>
          <span><strong>ทะเบียนวัว</strong><small>ค้นหาและดูประวัติวัว</small></span>
          <Icon name="arrow" size={18} />
        </button>
        <button className="quick-card" onClick={() => go('review')}>
          <span className="quick-icon"><Icon name="review" /></span>
          <span><strong>Review Queue</strong><small>ตรวจข้อเสนอจาก AI</small></span>
          <Icon name="arrow" size={18} />
        </button>
      </div>

      <SectionTitle eyebrow="ข้อมูลล่าสุด" title="กิจกรรมของระบบ" />
      <div className="panel">
        <EmptyState title="ยังไม่เชื่อมข้อมูลจริง" body="หน้าจอนี้จะเริ่มแสดงกิจกรรมเมื่อ APP-003 เชื่อม API ที่ปลอดภัยกับ Supabase แล้ว" />
      </div>
    </>
  )
}

function Bulls({ go }: { go: (view: ViewId) => void }) {
  return (
    <>
      <SectionTitle
        eyebrow="ทะเบียนกลาง"
        title="วัวทั้งหมด"
        action={<button className="primary-button" disabled>เพิ่มวัว</button>}
      />
      <div className="toolbar">
        <label className="search-box">
          <Icon name="search" size={19} />
          <input placeholder="ค้นหาชื่อวัว คอก จังหวัด..." aria-label="ค้นหาวัว" />
        </label>
        <button className="filter-button">ตัวกรอง</button>
      </div>
      <div className="panel">
        <EmptyState
          title="ยังไม่มีข้อมูลวัวที่แสดงในหน้าแอป"
          body="ฐาน Production ยังไม่มีข้อมูลปลอม เมื่อเชื่อม API แล้ว วัวที่มีสิทธิ์มองเห็นจะปรากฏที่นี่"
          action={<button className="text-button" onClick={() => go('bull-profile')}>ดูโครงหน้ารายละเอียดวัว</button>}
        />
      </div>
    </>
  )
}

function BullProfile({ go }: { go: (view: ViewId) => void }) {
  return (
    <>
      <button className="back-button" onClick={() => go('bulls')}>← กลับทะเบียนวัว</button>
      <div className="profile-hero panel">
        <div className="profile-avatar"><Icon name="bull" size={48} /></div>
        <div className="profile-copy">
          <span className="status-chip neutral">ยังไม่ได้เลือกวัว</span>
          <h2>รายละเอียดวัว</h2>
          <p>โครงหน้านี้เตรียมไว้สำหรับข้อมูลประจำตัว คอก เจ้าของ จังหวัด และชื่อเรียกอื่น</p>
        </div>
      </div>
      <div className="detail-grid">
        <div className="panel metric-panel"><span>จำนวนครั้งที่ชน</span><strong>—</strong><small>Verified matches</small></div>
        <div className="panel metric-panel"><span>ชนะ</span><strong>—</strong><small>Win</small></div>
        <div className="panel metric-panel"><span>แพ้</span><strong>—</strong><small>Loss</small></div>
        <div className="panel metric-panel"><span>อัตราชนะ</span><strong>—</strong><small>Win rate</small></div>
      </div>
      <SectionTitle title="ประวัติการแข่งขัน" eyebrow="MATCH HISTORY" />
      <div className="panel"><EmptyState title="ยังไม่มีวัวที่ถูกเลือก" body="เมื่อเชื่อมข้อมูลจริง รายการคู่ชนจะเรียงตามวันที่พร้อมผลและสถานะการยืนยัน" /></div>
    </>
  )
}

function Matches({ go }: { go: (view: ViewId) => void }) {
  return (
    <>
      <SectionTitle eyebrow="การแข่งขัน" title="คู่ชนและผลการแข่งขัน" action={<button className="primary-button" onClick={() => go('entry')}>บันทึกคู่ชน</button>} />
      <div className="segmented" role="tablist" aria-label="ตัวกรองการแข่งขัน">
        <button className="active">ทั้งหมด</button><button>ยืนยันแล้ว</button><button>รอตรวจ</button>
      </div>
      <div className="panel">
        <EmptyState
          title="ยังไม่มีคู่ชนใน Production"
          body="หลังเชื่อม API หน้านี้จะแสดงวันที่ สนาม วัวทั้งสองฝั่ง ผล และสถานะ VERIFIED/PUBLISHED"
          action={<button className="text-button" onClick={() => go('match-detail')}>ดูโครงหน้ารายละเอียดคู่ชน</button>}
        />
      </div>
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
          <div><div className="bull-circle"><Icon name="bull" size={34} /></div><strong>วัวฝั่ง A</strong><small>ข้อมูล snapshot วันชน</small></div>
          <span className="vs-mark">VS</span>
          <div><div className="bull-circle"><Icon name="bull" size={34} /></div><strong>วัวฝั่ง B</strong><small>ข้อมูล snapshot วันชน</small></div>
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

function ManualEntry() {
  return (
    <>
      <SectionTitle eyebrow="ADMIN WORKFLOW" title="บันทึกผลการแข่งขัน" />
      <div className="notice-card">
        <strong>UI Preview</strong>
        <span>แบบฟอร์มนี้ยังไม่ส่งข้อมูลไป Supabase จนกว่าจะมี API boundary ใน APP-003</span>
      </div>
      <div className="stepper" aria-label="ขั้นตอนบันทึกคู่ชน">
        {['งาน / สนาม', 'วัวทั้งสองฝั่ง', 'ผลการแข่งขัน', 'ตรวจและยืนยัน'].map((step, index) => (
          <div className={index === 0 ? 'step active' : 'step'} key={step}><span>{index + 1}</span><small>{step}</small></div>
        ))}
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
        <div className="form-actions"><span>ต้องเชื่อม API ก่อนจึงจะบันทึกได้</span><button className="primary-button" disabled>บันทึกข้อมูล</button></div>
      </form>
    </>
  )
}

function ReviewQueue() {
  return (
    <>
      <SectionTitle eyebrow="HUMAN REVIEW" title="Review Queue" />
      <div className="review-summary">
        <div><span>รายการรอตรวจ</span><strong>—</strong></div>
        <div><span>ข้อมูลขัดแย้ง</span><strong>—</strong></div>
        <div><span>อาจเป็นวัวตัวเดียวกัน</span><strong>—</strong></div>
      </div>
      <div className="segmented"><button className="active">ทั้งหมด</button><button>ความขัดแย้ง</button><button>ชื่อซ้ำ</button></div>
      <div className="panel"><EmptyState title="ยังไม่มี Review Case ในหน้าแอป" body="เมื่อ AI pipeline และ Review API ถูกเชื่อม รายการจะมาพร้อมหลักฐาน คะแนนความมั่นใจ และคำสั่ง Approve / Reject / Merge" /></div>
    </>
  )
}

function Settings() {
  return (
    <>
      <SectionTitle eyebrow="ระบบ" title="โปรไฟล์และการตั้งค่า" />
      <div className="panel settings-list">
        <div><span>บัญชีผู้ใช้</span><strong>ยังไม่ได้เชื่อม Supabase Auth</strong></div>
        <div><span>บทบาท BullMatch</span><strong>—</strong></div>
        <div><span>สภาพแวดล้อม</span><strong>UI Foundation</strong></div>
        <div><span>API</span><strong>ยังไม่เชื่อม</strong></div>
      </div>
    </>
  )
}

function App() {
  const initialView = useMemo<ViewId>(() => {
    const hash = window.location.hash.replace('#/', '').replace('#', '') as ViewId
    return hash && ['dashboard','bulls','bull-profile','matches','match-detail','entry','review','settings'].includes(hash) ? hash : 'dashboard'
  }, [])
  const [view, setView] = useState<ViewId>(initialView)

  useEffect(() => {
    const onHash = () => {
      const next = window.location.hash.replace('#/', '').replace('#', '') as ViewId
      if (['dashboard','bulls','bull-profile','matches','match-detail','entry','review','settings'].includes(next)) setView(next)
    }
    window.addEventListener('hashchange', onHash)
    return () => window.removeEventListener('hashchange', onHash)
  }, [])

  const go = (next: ViewId) => {
    setView(next)
    window.location.hash = `/${next}`
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const activeMain = mainViews.includes(view) ? view : view === 'bull-profile' ? 'bulls' : view === 'match-detail' ? 'matches' : 'dashboard'

  let content: React.ReactNode
  if (view === 'dashboard') content = <Dashboard go={go} />
  else if (view === 'bulls') content = <Bulls go={go} />
  else if (view === 'bull-profile') content = <BullProfile go={go} />
  else if (view === 'matches') content = <Matches go={go} />
  else if (view === 'match-detail') content = <MatchDetail go={go} />
  else if (view === 'entry') content = <ManualEntry />
  else if (view === 'review') content = <ReviewQueue />
  else content = <Settings />

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <Brand />
        <nav className="side-nav" aria-label="เมนูหลัก">
          {navItems.map((item) => (
            <button key={item.id} className={activeMain === item.id ? 'active' : ''} onClick={() => go(item.id)}>
              <Icon name={item.icon} /><span>{item.label}</span>
            </button>
          ))}
        </nav>
        <button className={view === 'settings' ? 'settings-button active' : 'settings-button'} onClick={() => go('settings')}>
          <Icon name="settings" /><span>การตั้งค่า</span>
        </button>
      </aside>

      <div className="app-body">
        <header className="topbar">
          <div className="mobile-brand"><Brand /></div>
          <div className="topbar-copy"><span>ฐานข้อมูลกีฬาวัวชน</span><strong>Verified sports intelligence</strong></div>
          <button className="user-button" onClick={() => go('settings')} aria-label="เปิดการตั้งค่า">ก</button>
        </header>
        <main>{content}</main>
      </div>

      <nav className="bottom-nav" aria-label="เมนูมือถือ">
        {navItems.map((item) => (
          <button key={item.id} className={activeMain === item.id ? 'active' : ''} onClick={() => go(item.id)}>
            <Icon name={item.icon} size={21} /><span>{item.label}</span>
          </button>
        ))}
      </nav>
    </div>
  )
}

export default App
