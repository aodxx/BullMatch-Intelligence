export type DataCoverageSignal = {
  label: string
  value: string
  detail?: string
  state?: 'verified' | 'available' | 'missing' | 'neutral'
}

export default function DataCoverageRail({
  title = 'DATA COVERAGE',
  signals,
}: {
  title?: string
  signals: DataCoverageSignal[]
}) {
  return <section className="data-coverage" aria-label="สถานะและขอบเขตข้อมูล">
    <div className="data-coverage-heading">
      <span>{title}</span>
      <small>แสดงสิ่งที่ฐานข้อมูลยืนยันได้จริง ไม่ใช่คะแนนทำนาย</small>
    </div>
    <div className="data-coverage-signals">
      {signals.map((signal) => <div className={`coverage-signal ${signal.state ?? 'neutral'}`} key={`${signal.label}-${signal.value}`}>
        <span>{signal.label}</span>
        <strong>{signal.value}</strong>
        {signal.detail && <small>{signal.detail}</small>}
      </div>)}
    </div>
  </section>
}
