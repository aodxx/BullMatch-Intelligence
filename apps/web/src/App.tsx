import { useEffect, useMemo, useState } from 'react'
import { type AuthSession, restoreSession, signInWithPassword, signOutLocal } from './auth'
import {
  type BullListItem,
  type BullProfileData,
  type DashboardData,
  type MatchItem,
  type MeData,
  getBull,
  getBulls,
  getDashboard,
  getMatch,
  getMatches,
  getMe,
} from './api'

type ViewId = 'dashboard'|'bulls'|'bull-profile'|'matches'|'match-detail'|'entry'|'review'|'settings'|'login'
type IconName = 'home'|'bull'|'match'|'plus'|'review'|'settings'|'arrow'|'search'

const allViews: ViewId[] = ['dashboard','bulls','bull-profile','matches','match-detail','entry','review','settings','login']
const mainViews: ViewId[] = ['dashboard','bulls','matches','entry','review']
const protectedViews = new Set<ViewId>(['entry','review'])
const navItems: Array<{id:ViewId;label:string;icon:IconName}> = [
  {id:'dashboard',label:'ภาพรวม',icon:'home'},
  {id:'bulls',label:'วัว',icon:'bull'},
  {id:'matches',label:'คู่ชน',icon:'match'},
  {id:'entry',label:'บันทึก',icon:'plus'},
  {id:'review',label:'ตรวจสอบ',icon:'review'},
]

function Icon({name,size=22}:{name:IconName;size?:number}) {
  const common={width:size,height:size,viewBox:'0 0 24 24',fill:'none',stroke:'currentColor',strokeWidth:1.8,strokeLinecap:'round' as const,strokeLinejoin:'round' as const,'aria-hidden':true}
  if(name==='home') return <svg {...common}><path d="M3 11.5 12 4l9 7.5"/><path d="M5.5 10.5V20h13v-9.5"/><path d="M9.5 20v-6h5v6"/></svg>
  if(name==='bull') return <svg {...common}><path d="M7 8c-2.2-.2-3.6-1.3-4-3 2.5-.4 4.5.2 5.5 1.8"/><path d="M17 8c2.2-.2 3.6-1.3 4-3-2.5-.4-4.5.2-5.5 1.8"/><path d="M7.5 7.5C8.6 6.5 10 6 12 6s3.4.5 4.5 1.5c1.1 1 1.5 2.5 1.5 4.2 0 4.6-2.3 7.3-6 7.3s-6-2.7-6-7.3c0-1.7.4-3.2 1.5-4.2Z"/><path d="M9 12h.01M15 12h.01"/><path d="M10 15.5c1.3.7 2.7.7 4 0"/></svg>
  if(name==='match') return <svg {...common}><path d="M8 5h8"/><path d="M7 4h10v3c0 3.3-2.2 6-5 6s-5-2.7-5-6V4Z"/><path d="M12 13v4"/><path d="M8.5 20h7"/><path d="M10 17h4"/><path d="M5 6H3.5v1.5A3.5 3.5 0 0 0 7 11"/><path d="M19 6h1.5v1.5A3.5 3.5 0 0 1 17 11"/></svg>
  if(name==='plus') return <svg {...common}><circle cx="12" cy="12" r="9"/><path d="M12 8v8M8 12h8"/></svg>
  if(name==='review') return <svg {...common}><path d="M8 4h8"/><path d="M9 3h6v3H9z"/><path d="M6 5h12v16H6z"/><path d="m9 13 2 2 4-5"/></svg>
  if(name==='settings') return <svg {...common}><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1l2-1.5-2-3.4-2.4 1a8 8 0 0 0-1.7-1L14.5 3h-5l-.4 3.1a8 8 0 0 0-1.7 1l-2.4-1-2 3.4L5 11a7 7 0 0 0 0 2l-2 1.5 2 3.4 2.4-1a8 8 0 0 0 1.7 1l.4 3.1h5l.4-3.1a8 8 0 0 0 1.7-1l2.4 1 2-3.4L19 13a7 7 0 0 0 0-1Z"/></svg>
  if(name==='search') return <svg {...common}><circle cx="11" cy="11" r="6"/><path d="m16 16 4 4"/></svg>
  return <svg {...common}><path d="M5 12h14M14 7l5 5-5 5"/></svg>
}

function Brand(){return <div className="brand"><div className="brand-mark"><Icon name="bull" size={27}/></div><div><strong>BullMatch</strong><span>Intelligence</span></div></div>}
function EmptyState({title,body,action}:{title:string;body:string;action?:React.ReactNode}){return <div className="empty-state"><div className="empty-icon"><Icon name="bull" size={34}/></div><h3>{title}</h3><p>{body}</p>{action}</div>}
function SectionTitle({eyebrow,title,action}:{eyebrow?:string;title:string;action?:React.ReactNode}){return <div className="section-title"><div>{eyebrow&&<span className="eyebrow">{eyebrow}</span>}<h2>{title}</h2></div>{action}</div>}
function LoadingPanel({label='กำลังโหลดข้อมูลจริง'}:{label?:string}){return <div className="panel"><EmptyState title={label} body="กำลังอ่านข้อมูล VERIFIED/PUBLISHED ผ่าน BullMatch API…"/></div>}
function ErrorPanel({message,retry}:{message:string;retry:()=>void}){return <div className="panel"><EmptyState title="โหลดข้อมูลไม่สำเร็จ" body={message} action={<button className="primary-button" onClick={retry}>ลองใหม่</button>}/></div>}
function fmtDate(value:string|null|undefined){if(!value)return '—';try{return new Intl.DateTimeFormat('th-TH',{dateStyle:'medium'}).format(new Date(value))}catch{return value}}
function fmtPct(value:number|null|undefined){return value==null?'—':`${Number(value).toFixed(2)}%`}

function Dashboard({go}:{go:(view:ViewId)=>void}){
  const [data,setData]=useState<DashboardData|null>(null),[loading,setLoading]=useState(true),[error,setError]=useState<string|null>(null),[tick,setTick]=useState(0)
  useEffect(()=>{let active=true;setLoading(true);setError(null);getDashboard().then(v=>{if(active)setData(v)}).catch(e=>{if(active)setError(e instanceof Error?e.message:'โหลดไม่สำเร็จ')}).finally(()=>{if(active)setLoading(false)});return()=>{active=false}},[tick])
  const stats=[['วัว VERIFIED',data?.bulls??'—','พร้อมสร้างสถิติ'],['คู่ชนเผยแพร่',data?.published_matches??'—','VERIFIED + PUBLISHED'],['สนาม VERIFIED',data?.venues??'—','ข้อมูลสาธารณะ'],['อัปเดตล่าสุด',data?.last_published_at?fmtDate(data.last_published_at):'—','เวลาที่เผยแพร่คู่ชนล่าสุด']]
  return <>
    <section className="hero-card"><div><span className="eyebrow light">BULLMATCH INTELLIGENCE</span><h1>ข้อมูลวัวชนที่ตรวจสอบย้อนกลับได้</h1><p>สถิติและประวัติที่แสดงต่อสาธารณะอ่านจากข้อมูล VERIFIED/PUBLISHED ผ่าน API boundary เท่านั้น</p></div><div className="hero-badge"><span className="pulse-dot"/>Production API</div></section>
    {error?<ErrorPanel message={error} retry={()=>setTick(v=>v+1)}/>:loading?<LoadingPanel/>:<div className="stat-grid">{stats.map(([l,v,n])=><article className="stat-card" key={String(l)}><span>{l}</span><strong>{v}</strong><small>{n}</small></article>)}</div>}
    <SectionTitle eyebrow="ทางลัด" title="เริ่มงาน"/><div className="quick-grid">
      <button className="quick-card" onClick={()=>go('entry')}><span className="quick-icon"><Icon name="plus"/></span><span><strong>บันทึกคู่ชน</strong><small>เฉพาะ ACTIVE ADMIN</small></span><Icon name="arrow" size={18}/></button>
      <button className="quick-card" onClick={()=>go('bulls')}><span className="quick-icon"><Icon name="bull"/></span><span><strong>ทะเบียนวัว</strong><small>ข้อมูลและสถิติจริง</small></span><Icon name="arrow" size={18}/></button>
      <button className="quick-card" onClick={()=>go('review')}><span className="quick-icon"><Icon name="review"/></span><span><strong>Review Queue</strong><small>ตรวจสิทธิ์จาก server</small></span><Icon name="arrow" size={18}/></button>
    </div>
  </>
}

function Bulls({openBull,isAdmin}:{openBull:(id:string)=>void;isAdmin:boolean}){
  const [items,setItems]=useState<BullListItem[]>([]),[search,setSearch]=useState(''),[loading,setLoading]=useState(true),[error,setError]=useState<string|null>(null),[tick,setTick]=useState(0)
  useEffect(()=>{let active=true;const timer=setTimeout(()=>{setLoading(true);setError(null);getBulls(search.trim()||undefined).then(v=>{if(active)setItems(v)}).catch(e=>{if(active)setError(e instanceof Error?e.message:'โหลดไม่สำเร็จ')}).finally(()=>{if(active)setLoading(false)})},250);return()=>{active=false;clearTimeout(timer)}},[search,tick])
  return <>
    <SectionTitle eyebrow="ทะเบียนกลาง" title="วัวทั้งหมด" action={<button className="primary-button" disabled={!isAdmin} title={isAdmin?'CRUD form จะเปิดในงานถัดไป':'ต้องเป็น ACTIVE ADMIN'}>เพิ่มวัว</button>}/>
    <div className="toolbar"><label className="search-box"><Icon name="search" size={19}/><input value={search} onChange={e=>setSearch(e.target.value)} placeholder="ค้นหาชื่อวัว คอก จังหวัด..." aria-label="ค้นหาวัว"/></label></div>
    {error?<ErrorPanel message={error} retry={()=>setTick(v=>v+1)}/>:loading?<LoadingPanel/>:items.length===0?<div className="panel"><EmptyState title="ยังไม่มีวัว VERIFIED ใน Production" body="ระบบไม่สร้างข้อมูลตัวอย่าง วัวจะปรากฏที่นี่เมื่อถูกบันทึกและยืนยันแล้ว"/></div>:<div className="data-list">{items.map(b=><button className="data-card" key={b.id} onClick={()=>openBull(b.id)}><div><strong>{b.canonical_name}</strong><span>{[b.camp_name,b.home_province].filter(Boolean).join(' • ')||'ไม่ระบุคอก/จังหวัด'}</span></div><div className="record-stats"><span>{b.wins}W {b.losses}L {b.draws}D</span><b>{fmtPct(b.win_rate_pct)}</b></div></button>)}</div>}
  </>
}

function BullProfile({id,go}:{id:string|null;go:(v:ViewId)=>void}){
  const [data,setData]=useState<BullProfileData|null>(null),[loading,setLoading]=useState(Boolean(id)),[error,setError]=useState<string|null>(null),[tick,setTick]=useState(0)
  useEffect(()=>{if(!id){setData(null);setLoading(false);return}let active=true;setLoading(true);setError(null);getBull(id).then(v=>{if(active)setData(v)}).catch(e=>{if(active)setError(e instanceof Error?e.message:'โหลดไม่สำเร็จ')}).finally(()=>{if(active)setLoading(false)});return()=>{active=false}},[id,tick])
  return <><button className="back-button" onClick={()=>go('bulls')}>← กลับทะเบียนวัว</button>{!id?<div className="panel"><EmptyState title="ยังไม่ได้เลือกวัว" body="เลือกวัวจากทะเบียนเพื่อดูสถิติและประวัติ"/></div>:error?<ErrorPanel message={error} retry={()=>setTick(v=>v+1)}/>:loading?<LoadingPanel/>:!data?<div className="panel"><EmptyState title="ไม่พบวัวที่เผยแพร่" body="วัวอาจยังไม่ผ่านการยืนยันหรือถูกเก็บถาวร"/></div>:<>
    <div className="profile-hero panel"><div className="profile-avatar"><Icon name="bull" size={48}/></div><div className="profile-copy"><span className="status-chip neutral">VERIFIED</span><h2>{data.bull.canonical_name}</h2><p>{[data.bull.camp?.name,data.bull.owner?.name,data.bull.home_province].filter(Boolean).join(' • ')||'ยังไม่มีข้อมูลคอก/เจ้าของ/จังหวัด'}</p></div></div>
    <div className="detail-grid"><div className="panel metric-panel"><span>จำนวนครั้งที่ชน</span><strong>{data.stats.published_matches}</strong><small>Published</small></div><div className="panel metric-panel"><span>ชนะ</span><strong>{data.stats.wins}</strong><small>Win</small></div><div className="panel metric-panel"><span>แพ้ / เสมอ</span><strong>{data.stats.losses} / {data.stats.draws}</strong><small>Loss / Draw</small></div><div className="panel metric-panel"><span>อัตราชนะ</span><strong>{fmtPct(data.stats.win_rate_pct)}</strong><small>W / (W+L+D)</small></div></div>
    <SectionTitle eyebrow="RECENT FORM" title={`ฟอร์มล่าสุด ${data.recent_form.length?data.recent_form.join(' • '):'—'}`}/>
    <SectionTitle eyebrow="MATCH HISTORY" title="ประวัติการแข่งขัน"/>
    {data.history.length===0?<div className="panel"><EmptyState title="ยังไม่มีประวัติการแข่งขันที่เผยแพร่" body="NO_RESULT/CANCELLED จะแสดงในประวัติแต่ไม่ถูกนำไปคิด win rate"/></div>:<div className="data-list">{data.history.map(h=><article className="history-card panel" key={`${h.match_id}-${h.opponent_bull_id??'none'}`}><div><strong>{h.result??h.result_type}</strong><span>{fmtDate(h.match_date)} • {h.venue_name??'ไม่ระบุสนาม'}</span></div><div><span>คู่ต่อสู้</span><b>{h.opponent_name??'—'}</b></div></article>)}</div>}
  </>}</>
}

function Matches({openMatch,go,isAdmin}:{openMatch:(id:string)=>void;go:(v:ViewId)=>void;isAdmin:boolean}){
  const [items,setItems]=useState<MatchItem[]>([]),[loading,setLoading]=useState(true),[error,setError]=useState<string|null>(null),[tick,setTick]=useState(0)
  useEffect(()=>{let active=true;setLoading(true);setError(null);getMatches().then(v=>{if(active)setItems(v)}).catch(e=>{if(active)setError(e instanceof Error?e.message:'โหลดไม่สำเร็จ')}).finally(()=>{if(active)setLoading(false)});return()=>{active=false}},[tick])
  return <><SectionTitle eyebrow="การแข่งขัน" title="คู่ชนและผลการแข่งขัน" action={<button className="primary-button" onClick={()=>go('entry')}>{isAdmin?'บันทึกคู่ชน':'เข้าสู่พื้นที่บันทึก'}</button>}/>{error?<ErrorPanel message={error} retry={()=>setTick(v=>v+1)}/>:loading?<LoadingPanel/>:items.length===0?<div className="panel"><EmptyState title="ยังไม่มีคู่ชน VERIFIED/PUBLISHED" body="ระบบแสดงเฉพาะผลที่ยืนยันและเผยแพร่แล้ว"/></div>:<div className="data-list">{items.map(m=><button className="data-card match-row" key={m.id} onClick={()=>openMatch(m.id)}><div><strong>{m.participants.map(p=>p.display_name).join(' VS ')}</strong><span>{fmtDate(m.match_date)} • {m.venue?.name??'ไม่ระบุสนาม'}</span></div><div className="record-stats"><span>{m.result.type}</span><b>ดูรายละเอียด</b></div></button>)}</div>}</>
}

function MatchDetail({id,go}:{id:string|null;go:(v:ViewId)=>void}){
  const [data,setData]=useState<MatchItem|null>(null),[loading,setLoading]=useState(Boolean(id)),[error,setError]=useState<string|null>(null),[tick,setTick]=useState(0)
  useEffect(()=>{if(!id){setData(null);setLoading(false);return}let active=true;setLoading(true);setError(null);getMatch(id).then(v=>{if(active)setData(v)}).catch(e=>{if(active)setError(e instanceof Error?e.message:'โหลดไม่สำเร็จ')}).finally(()=>{if(active)setLoading(false)});return()=>{active=false}},[id,tick])
  return <><button className="back-button" onClick={()=>go('matches')}>← กลับรายการคู่ชน</button>{!id?<div className="panel"><EmptyState title="ยังไม่ได้เลือกคู่ชน" body="เลือกคู่ชนจากรายการเพื่อดูรายละเอียด"/></div>:error?<ErrorPanel message={error} retry={()=>setTick(v=>v+1)}/>:loading?<LoadingPanel/>:!data?<div className="panel"><EmptyState title="ไม่พบคู่ชนที่เผยแพร่" body="รายการอาจยังไม่ VERIFIED/PUBLISHED"/></div>:<>
    <div className="match-card panel"><div className="match-meta"><span className="status-chip neutral">VERIFIED / PUBLISHED</span><span>{data.venue?.name??'สนาม —'}</span></div><div className="versus">{data.participants.slice(0,2).map((p,i)=><div key={p.id}><div className="bull-circle"><Icon name="bull" size={34}/></div><strong>{p.display_name}</strong><small>{p.weight_kg?`${p.weight_kg} กก.`:'snapshot วันชน'}</small>{i===0&&null}</div>)}</div><div className="result-placeholder">ผลการแข่งขัน: {data.result.type}</div></div>
    <div className="detail-grid two"><div className="panel"><h3>ข้อมูลการแข่งขัน</h3><dl className="definition-list"><div><dt>วันที่</dt><dd>{fmtDate(data.match_date)}</dd></div><div><dt>สนาม</dt><dd>{data.venue?.name??'—'}</dd></div><div><dt>ระยะเวลา</dt><dd>{data.duration_seconds==null?'—':`${data.duration_seconds} วินาที`}</dd></div></dl></div><div className="panel"><h3>ผลที่ตรวจสอบแล้ว</h3><dl className="definition-list"><div><dt>ประเภทผล</dt><dd>{data.result.type}</dd></div><div><dt>เหตุผล</dt><dd>{data.result.reason??'—'}</dd></div><div><dt>เผยแพร่</dt><dd>{fmtDate(data.published_at)}</dd></div></dl></div></div>
  </>}</>
}

function AccessGate({title,body}:{title:string;body:string}){return <div className="panel"><EmptyState title={title} body={body}/></div>}
function ManualEntry({session,me}:{session:AuthSession;me:MeData|null}){
  const isAdmin=Boolean(me?.membership.active&&me.membership.role==='ADMIN')
  return <><SectionTitle eyebrow="ADMIN WORKFLOW" title="บันทึกผลการแข่งขัน"/>{!isAdmin?<AccessGate title="บัญชีนี้ยังไม่มีสิทธิ์ ADMIN" body={me?.membership.member?'ต้องเป็น ACTIVE ADMIN จึงจะส่งคำสั่งแก้ข้อมูลได้':'บัญชี Auth นี้ยังไม่ได้ถูกเพิ่มใน BullMatch app_users'}/>:<><div className="notice-card success"><strong>ACTIVE ADMIN</strong><span>{session.user.email??session.user.id} • API dispatcher พร้อมใช้งานและตรวจสิทธิ์ซ้ำใน Database</span></div><div className="panel"><EmptyState title="Mutation boundary พร้อมแล้ว" body="การบันทึกคู่ชนแบบหลายขั้นจะเปิดเมื่อรวม Event → Match → Participants → Result เป็นคำสั่ง atomic เดียว เพื่อป้องกันข้อมูลค้างครึ่งทาง"/></div></>}</>
}
function ReviewQueue({me}:{me:MeData|null}){
  const allowed=Boolean(me?.membership.active&&['ADMIN','REVIEWER'].includes(me.membership.role??''))
  return <><SectionTitle eyebrow="HUMAN REVIEW" title="Review Queue"/>{!allowed?<AccessGate title="ไม่มีสิทธิ์ Review" body="ต้องเป็น ACTIVE ADMIN หรือ REVIEWER และ P1-008 จะเปิด Review API รายการจริง"/>:<><div className="notice-card success"><strong>{me?.membership.role}</strong><span>ยืนยันสิทธิ์จาก server แล้ว</span></div><div className="panel"><EmptyState title="Review backend ยังเป็นงาน P1-008" body="Auth และ role gate พร้อมแล้ว แต่ evidence/approve/reject/merge API ยังไม่เปิดใน APP-003"/></div></>}</>
}

function Login({onSignedIn,go}:{onSignedIn:(s:AuthSession)=>void;go:(v:ViewId)=>void}){
  const[email,setEmail]=useState(''),[password,setPassword]=useState(''),[pending,setPending]=useState(false),[error,setError]=useState<string|null>(null)
  const submit=async(e:React.FormEvent<HTMLFormElement>)=>{e.preventDefault();setError(null);if(!email.trim()||!password){setError('กรุณากรอกอีเมลและรหัสผ่าน');return}setPending(true);try{onSignedIn(await signInWithPassword(email,password))}catch(err){setError(err instanceof Error?err.message:'เข้าสู่ระบบไม่สำเร็จ')}finally{setPending(false)}}
  return <div className="auth-page"><div className="auth-card panel"><div className="auth-brand"><div className="profile-avatar"><Icon name="bull" size={42}/></div><div><span className="eyebrow">SECURE ACCESS</span><h2>เข้าสู่ระบบ BullMatch</h2></div></div><p className="auth-intro">สำหรับบัญชีที่สร้างไว้ใน Supabase Auth เท่านั้น ไม่มี Sign Up สาธารณะ</p><form className="auth-form" onSubmit={submit}><label><span>อีเมล</span><input type="email" autoComplete="username" value={email} onChange={e=>setEmail(e.target.value)}/></label><label><span>รหัสผ่าน</span><input type="password" autoComplete="current-password" value={password} onChange={e=>setPassword(e.target.value)}/></label>{error&&<div className="auth-error" role="alert">{error}</div>}<button className="primary-button auth-submit" disabled={pending}>{pending?'กำลังเข้าสู่ระบบ…':'เข้าสู่ระบบ'}</button></form><button className="text-button" onClick={()=>go('dashboard')}>กลับหน้าสาธารณะ</button></div></div>
}
function Settings({session,authLoading,me,meLoading,meError,onLogin,onLogout}:{session:AuthSession|null;authLoading:boolean;me:MeData|null;meLoading:boolean;meError:string|null;onLogin:()=>void;onLogout:()=>Promise<void>}){
  return <><SectionTitle eyebrow="ระบบ" title="โปรไฟล์และการตั้งค่า"/><div className="panel settings-list"><div><span>บัญชีผู้ใช้</span><strong>{authLoading?'กำลังตรวจ session…':session?.user.email??'ยังไม่ได้เข้าสู่ระบบ'}</strong></div><div><span>Supabase Auth</span><strong>{session?'SIGNED IN':'SIGNED OUT'}</strong></div><div><span>บทบาท BullMatch</span><strong>{!session?'—':meLoading?'กำลังตรวจ…':meError?'ตรวจไม่สำเร็จ':me?.membership.member?`${me.membership.role} / ${me.membership.status}`:'NOT A MEMBER'}</strong></div><div><span>API boundary</span><strong>Edge Function → service-only RPC</strong></div></div>{meError&&<div className="notice-card"><strong>Role API</strong><span>{meError}</span></div>}<div className="settings-actions">{session?<button className="secondary-button" onClick={()=>void onLogout()}>ออกจากระบบ</button>:<button className="primary-button" onClick={onLogin}>เข้าสู่ระบบ</button>}</div></>
}
function AuthLoading(){return <LoadingPanel label="กำลังตรวจสอบการเข้าสู่ระบบ"/>}

function App(){
  const initialView=useMemo<ViewId>(()=>{const h=window.location.hash.replace('#/','').replace('#','') as ViewId;return h&&allViews.includes(h)?h:'dashboard'},[])
  const[view,setView]=useState<ViewId>(initialView),[session,setSession]=useState<AuthSession|null>(null),[authLoading,setAuthLoading]=useState(true),[returnAfterLogin,setReturnAfterLogin]=useState<ViewId|null>(null)
  const[me,setMe]=useState<MeData|null>(null),[meLoading,setMeLoading]=useState(false),[meError,setMeError]=useState<string|null>(null)
  const[selectedBullId,setSelectedBullId]=useState<string|null>(null),[selectedMatchId,setSelectedMatchId]=useState<string|null>(null)
  const setLocation=(next:ViewId)=>{setView(next);window.location.hash=`/${next}`;window.scrollTo({top:0,behavior:'smooth'})}
  useEffect(()=>{let active=true;restoreSession().then(r=>{if(!active)return;setSession(r);setAuthLoading(false);const h=window.location.hash.replace('#/','').replace('#','') as ViewId;if(!r&&protectedViews.has(h)){setReturnAfterLogin(h);setLocation('login')}});return()=>{active=false}},[])
  useEffect(()=>{if(!session){setMe(null);setMeError(null);setMeLoading(false);return}let active=true;setMeLoading(true);setMeError(null);getMe(session).then(v=>{if(active)setMe(v)}).catch(e=>{if(active){setMe(null);setMeError(e instanceof Error?e.message:'ตรวจ role ไม่สำเร็จ')}}).finally(()=>{if(active)setMeLoading(false)});return()=>{active=false}},[session])
  useEffect(()=>{const onHash=()=>{const next=window.location.hash.replace('#/','').replace('#','') as ViewId;if(!allViews.includes(next))return;if(!authLoading&&!session&&protectedViews.has(next)){setReturnAfterLogin(next);setView('login');if(window.location.hash!=='#/login')window.location.hash='/login';return}setView(next)};window.addEventListener('hashchange',onHash);return()=>window.removeEventListener('hashchange',onHash)},[authLoading,session])
  const go=(next:ViewId)=>{if(protectedViews.has(next)&&!session){setReturnAfterLogin(next);setLocation('login');return}setLocation(next)}
  const openBull=(id:string)=>{setSelectedBullId(id);setLocation('bull-profile')},openMatch=(id:string)=>{setSelectedMatchId(id);setLocation('match-detail')}
  const handleSignedIn=(s:AuthSession)=>{setSession(s);const target=returnAfterLogin??'settings';setReturnAfterLogin(null);setLocation(target)}
  const handleLogout=async()=>{const current=session;setSession(null);setMe(null);await signOutLocal(current);if(protectedViews.has(view))setLocation('dashboard')}
  const isAdmin=Boolean(me?.membership.active&&me.membership.role==='ADMIN')
  const activeMain=mainViews.includes(view)?view:view==='bull-profile'?'bulls':view==='match-detail'?'matches':'dashboard'
  let content:React.ReactNode
  if(authLoading&&protectedViews.has(view))content=<AuthLoading/>
  else if(view==='dashboard')content=<Dashboard go={go}/>
  else if(view==='bulls')content=<Bulls openBull={openBull} isAdmin={isAdmin}/>
  else if(view==='bull-profile')content=<BullProfile id={selectedBullId} go={go}/>
  else if(view==='matches')content=<Matches openMatch={openMatch} go={go} isAdmin={isAdmin}/>
  else if(view==='match-detail')content=<MatchDetail id={selectedMatchId} go={go}/>
  else if(view==='entry'&&session)content=<ManualEntry session={session} me={me}/>
  else if(view==='review'&&session)content=<ReviewQueue me={me}/>
  else if(view==='login')content=session?<Settings session={session} authLoading={false} me={me} meLoading={meLoading} meError={meError} onLogin={()=>go('login')} onLogout={handleLogout}/>:<Login onSignedIn={handleSignedIn} go={go}/>
  else content=<Settings session={session} authLoading={authLoading} me={me} meLoading={meLoading} meError={meError} onLogin={()=>go('login')} onLogout={handleLogout}/>
  const userLabel=session?.user.email?.trim().charAt(0).toUpperCase()||(session?'✓':'เข้า')
  return <div className="app-shell"><aside className="sidebar"><Brand/><nav className="side-nav" aria-label="เมนูหลัก">{navItems.map(item=><button key={item.id} className={activeMain===item.id?'active':''} onClick={()=>go(item.id)}><Icon name={item.icon}/><span>{item.label}</span></button>)}</nav><button className={view==='settings'||view==='login'?'settings-button active':'settings-button'} onClick={()=>go('settings')}><Icon name="settings"/><span>การตั้งค่า</span></button></aside><div className="app-body"><header className="topbar"><div className="mobile-brand"><Brand/></div><div className="topbar-copy"><span>ฐานข้อมูลกีฬาวัวชน</span><strong>{session?(me?.membership.role?`${me.membership.role} • ${session.user.email??'ผู้ใช้'}`:`เข้าสู่ระบบ • ${session.user.email??'ผู้ใช้'}`):'Public mode • Verified data only'}</strong></div><button className={session?'user-button signed-in':'user-button'} onClick={()=>go(session?'settings':'login')} aria-label={session?'เปิดโปรไฟล์ผู้ใช้':'เข้าสู่ระบบ'}>{userLabel}</button></header><main>{content}</main></div><nav className="bottom-nav" aria-label="เมนูมือถือ">{navItems.map(item=><button key={item.id} className={activeMain===item.id?'active':''} onClick={()=>go(item.id)}><Icon name={item.icon} size={21}/><span>{item.label}</span></button>)}</nav></div>
}
export default App
