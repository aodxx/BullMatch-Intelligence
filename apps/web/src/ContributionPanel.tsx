import { type FormEvent, useCallback, useEffect, useMemo, useState } from 'react'
import { type AuthSession } from './auth'
import {
  type BullProfileData,
  type ContributionField,
  type MySubmissionItem,
  getBull,
  getMySubmissions,
  submitBullProfileCorrection,
} from './api'
import './contribution.css'

const FIELD_OPTIONS: Array<{value:ContributionField;label:string;hint:string}> = [
  {value:'home_province',label:'จังหวัดประจำถิ่น',hint:'จังหวัดที่วัวอยู่หรือถูกอ้างอิงว่าเป็นถิ่นหลัก'},
  {value:'home_district',label:'อำเภอประจำถิ่น',hint:'อำเภอ/พื้นที่ย่อยของถิ่นหลัก'},
  {value:'color_description',label:'ลักษณะสี',hint:'คำบรรยายสีหรือลักษณะสีจากหลักฐาน'},
  {value:'breed_description',label:'คำบรรยายสายพันธุ์',hint:'ข้อมูลสายพันธุ์ตามที่แหล่งอ้างอิงระบุโดยตรง'},
]

const OUTCOME_LABEL: Record<string,string> = {
  PENDING_REVIEW:'รอตรวจสอบ',
  ACCEPTED:'ยืนยันข้อมูลแล้ว',
  REJECTED:'ไม่รับข้อมูลนี้',
  CONFLICT:'พบข้อมูลขัดแย้ง',
  SUPERSEDED:'มีข้อมูลใหม่กว่า',
  WITHDRAWN:'ยกเลิกแล้ว',
}

function formatDate(value:string|null|undefined){
  if(!value)return '—'
  try{return new Intl.DateTimeFormat('th-TH',{dateStyle:'medium',timeStyle:'short'}).format(new Date(value))}catch{return value}
}

function newClientKey(){return crypto.randomUUID()}

export default function ContributionPanel({session,bullId,onChooseBull,onBack}:{session:AuthSession;bullId:string|null;onChooseBull:()=>void;onBack:()=>void}){
  const [mode,setMode]=useState<'submit'|'history'>('submit')
  const [bull,setBull]=useState<BullProfileData|null>(null)
  const [bullLoading,setBullLoading]=useState(Boolean(bullId))
  const [bullError,setBullError]=useState<string|null>(null)
  const [field,setField]=useState<ContributionField>('home_province')
  const [value,setValue]=useState('')
  const [sourceUrl,setSourceUrl]=useState('')
  const [note,setNote]=useState('')
  const [clientKey,setClientKey]=useState(newClientKey)
  const [submitting,setSubmitting]=useState(false)
  const [submitError,setSubmitError]=useState<string|null>(null)
  const [success,setSuccess]=useState<string|null>(null)
  const [history,setHistory]=useState<MySubmissionItem[]>([])
  const [historyLoading,setHistoryLoading]=useState(true)
  const [historyError,setHistoryError]=useState<string|null>(null)

  useEffect(()=>{
    if(!bullId){setBull(null);setBullLoading(false);setBullError(null);return}
    let active=true
    setBullLoading(true);setBullError(null)
    getBull(bullId).then(data=>{if(active)setBull(data)}).catch(error=>{if(active)setBullError(error instanceof Error?error.message:'โหลดวัวไม่สำเร็จ')}).finally(()=>{if(active)setBullLoading(false)})
    return()=>{active=false}
  },[bullId])

  const refreshHistory=useCallback(async()=>{
    setHistoryLoading(true);setHistoryError(null)
    try{const data=await getMySubmissions(session);setHistory(data.items)}catch(error){setHistoryError(error instanceof Error?error.message:'โหลดประวัติไม่สำเร็จ')}finally{setHistoryLoading(false)}
  },[session])

  useEffect(()=>{void refreshHistory()},[refreshHistory])

  const currentField=useMemo(()=>FIELD_OPTIONS.find(option=>option.value===field)??FIELD_OPTIONS[0],[field])

  const submit=async(event:FormEvent<HTMLFormElement>)=>{
    event.preventDefault();setSubmitError(null);setSuccess(null)
    if(!bull?.bull.id){setSubmitError('กรุณาเลือกวัว VERIFIED จากทะเบียนก่อน');return}
    if(!value.trim()){setSubmitError('กรุณากรอกข้อมูลที่ต้องการเสนอ');return}
    let parsed:URL
    try{parsed=new URL(sourceUrl.trim())}catch{setSubmitError('กรุณาใส่ลิงก์หลักฐาน HTTP/HTTPS ที่ถูกต้อง');return}
    if(!['http:','https:'].includes(parsed.protocol)){setSubmitError('หลักฐานต้องเป็นลิงก์ HTTP หรือ HTTPS');return}
    setSubmitting(true)
    try{
      const result=await submitBullProfileCorrection(session,{
        schema_version:'1.0.0',
        client_submission_key:clientKey,
        bull_id:bull.bull.id,
        field_key:field,
        proposed_value:value.trim(),
        source_url:parsed.href,
        ...(note.trim()?{note:note.trim()}:{}),
      })
      setSuccess(result.replayed?'คำขอนี้เคยถูกส่งแล้ว ระบบใช้รายการเดิมให้โดยไม่สร้างซ้ำ':'รับข้อมูลแล้ว และส่งเข้าคิวตรวจสอบเรียบร้อย โปรไฟล์วัวจะยังไม่เปลี่ยนจนกว่าจะผ่านการยืนยัน')
      setValue('');setSourceUrl('');setNote('');setClientKey(newClientKey())
      await refreshHistory()
    }catch(error){setSubmitError(error instanceof Error?error.message:'ส่งข้อมูลไม่สำเร็จ')}
    finally{setSubmitting(false)}
  }

  return <div className="contribution-page">
    <div className="contribution-topline">
      <button className="back-button" onClick={onBack}>← กลับ</button>
      <span className="contribution-policy">COMMUNITY EVIDENCE • REVIEW FIRST</span>
    </div>

    <section className="contribution-hero">
      <div><span className="eyebrow light">COMMUNITY DATA NETWORK</span><h1>ร่วมเพิ่มข้อมูลวัวชน</h1><p>เสนอข้อเท็จจริงพร้อมหลักฐานเข้าสู่ระบบตรวจสอบ ข้อมูลที่ส่งจะไม่เขียนทับประวัติหรือโปรไฟล์ที่ยืนยันแล้วทันที</p></div>
      <div className="contribution-steps" aria-label="ขั้นตอนการส่งข้อมูล"><span>01 เลือกวัว</span><span>02 ระบุข้อเท็จจริง</span><span>03 แนบแหล่งอ้างอิง</span><span>04 Human review</span></div>
    </section>

    <div className="contribution-tabs" role="tablist">
      <button className={mode==='submit'?'active':''} onClick={()=>setMode('submit')} role="tab" aria-selected={mode==='submit'}>ส่งข้อมูล</button>
      <button className={mode==='history'?'active':''} onClick={()=>setMode('history')} role="tab" aria-selected={mode==='history'}>การส่งข้อมูลของฉัน {history.length?`(${history.length})`:''}</button>
    </div>

    {mode==='submit'?<div className="contribution-layout">
      <aside className="contribution-target panel">
        <span className="eyebrow">TARGET • VERIFIED BULL</span>
        {bullLoading?<p>กำลังอ่านโปรไฟล์…</p>:bullError?<div className="auth-error">{bullError}</div>:bull?<><h2>{bull.bull.canonical_name}</h2><p>{[bull.bull.camp?.name,bull.bull.home_province].filter(Boolean).join(' • ')||'ยังไม่มีข้อมูลคอก/จังหวัด'}</p><span className="status-chip neutral">VERIFIED</span></>:<><h2>ยังไม่ได้เลือกวัว</h2><p>เพื่อป้องกันการสร้างตัวตนวัวซ้ำ V1 รับข้อมูลเฉพาะวัว VERIFIED ที่มีอยู่ในทะเบียนแล้ว</p></>}
        <button className="secondary-button" onClick={onChooseBull}>{bull?'เลือกวัวตัวอื่น':'ไปทะเบียนวัว'}</button>
      </aside>

      <form className="contribution-form panel" onSubmit={submit}>
        <div className="contribution-form-head"><div><span className="eyebrow">ATOMIC FACT</span><h2>เสนอข้อมูล 1 ข้อ</h2></div><span className="status-chip pending">REVIEW REQUIRED</span></div>
        <label><span>ประเภทข้อมูล</span><select value={field} onChange={event=>setField(event.target.value as ContributionField)}>{FIELD_OPTIONS.map(option=><option key={option.value} value={option.value}>{option.label}</option>)}</select><small>{currentField.hint}</small></label>
        <label><span>ข้อมูลที่เสนอ</span><input value={value} onChange={event=>setValue(event.target.value)} maxLength={500} placeholder="พิมพ์ตามที่หลักฐานระบุ"/><small>{value.length}/500</small></label>
        <label><span>ลิงก์หลักฐานสาธารณะ</span><input type="url" inputMode="url" value={sourceUrl} onChange={event=>setSourceUrl(event.target.value)} maxLength={2048} placeholder="https://…"/><small>ใช้โพสต์ ข่าว ผลการแข่งขัน หรือหน้าเว็บที่เปิดตรวจสอบได้</small></label>
        <label><span>หมายเหตุถึงผู้ตรวจสอบ <em>ไม่บังคับ</em></span><textarea value={note} onChange={event=>setNote(event.target.value)} maxLength={1000} rows={3} placeholder="อธิบายตำแหน่งหรือบริบทของข้อมูลในหลักฐาน"/></label>
        <div className="contribution-boundary"><strong>สิ่งที่จะเกิดขึ้นหลังส่ง</strong><p>ระบบจะเก็บหลักฐานและสร้าง claim สถานะ REVIEW_REQUIRED เท่านั้น ผู้ตรวจสอบต้องยืนยันก่อน และการนำข้อมูลไปเปลี่ยน canonical profile เป็นขั้นตอนแยกต่างหาก</p></div>
        {submitError&&<div className="auth-error" role="alert">{submitError}</div>}
        {success&&<div className="notice-card success" role="status"><strong>ส่งข้อมูลสำเร็จ</strong><span>{success}</span></div>}
        <button className="primary-button contribution-submit" disabled={submitting||!bull}>{submitting?'กำลังส่งเข้าคิวตรวจสอบ…':'ส่งข้อมูลพร้อมหลักฐาน'}</button>
      </form>
    </div>:<section className="contribution-history">
      <div className="section-title"><div><span className="eyebrow">CONTRIBUTOR FEEDBACK</span><h2>การส่งข้อมูลของฉัน</h2></div><button className="secondary-button" onClick={()=>void refreshHistory()} disabled={historyLoading}>รีเฟรช</button></div>
      {historyError?<div className="panel"><div className="auth-error">{historyError}</div></div>:historyLoading?<div className="panel"><p>กำลังอ่านสถานะจาก Production…</p></div>:history.length===0?<div className="panel contribution-empty"><h3>ยังไม่มีข้อมูลที่คุณส่ง</h3><p>เริ่มจากเลือกวัว VERIFIED ในทะเบียน แล้วเสนอข้อเท็จจริงพร้อมแหล่งอ้างอิง</p><button className="primary-button" onClick={()=>setMode('submit')}>เริ่มส่งข้อมูล</button></div>:<div className="contribution-list">{history.map(item=><SubmissionCard key={item.id} item={item}/>)}</div>}
    </section>}
  </div>
}

function SubmissionCard({item}:{item:MySubmissionItem}){
  const claim=item.claims[0]
  const outcome=claim?.outcome??'PENDING_REVIEW'
  return <article className="panel contribution-record">
    <div className="contribution-record-head"><div><span className="eyebrow">{item.submission_type}</span><h3>{item.target.bull_name??'วัวที่ไม่อยู่ใน public view แล้ว'}</h3></div><span className={`contribution-outcome outcome-${outcome.toLowerCase()}`}>{OUTCOME_LABEL[outcome]??outcome}</span></div>
    <div className="contribution-record-fact"><span>{FIELD_OPTIONS.find(option=>option.value===claim?.field_key)?.label??claim?.field_key??'ข้อเท็จจริง'}</span><strong>{claim?.proposed_value??'—'}</strong></div>
    <footer><span>ส่ง {formatDate(item.submitted_at)}</span><span>Submission {item.id.slice(0,8)}</span></footer>
  </article>
}
