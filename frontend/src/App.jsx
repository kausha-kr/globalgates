import { useCallback, useEffect, useMemo, useState } from 'react'
import './App.css'
import { getEstimations, updateEstimationStatus } from './api/estimations'
import { filterEstimations, formatStatus, normalizeStatus } from './domain/estimation'
import { mockEstimations } from './mocks/estimations'
import EstimationRegisterPage from './pages/EstimationRegisterPage'

const periods = [['7D', 7], ['2W', 14], ['4W', 28], ['3M', 90]]
const toDateInput = (date) => date.toISOString().slice(0, 10)

function EstimationListPage() {
  const mockMode = new URLSearchParams(window.location.search).get('mock') === 'true'
  const [items, setItems] = useState([])
  const [status, setStatus] = useState('all')
  const [endDate, setEndDate] = useState(toDateInput(new Date()))
  const [startDate, setStartDate] = useState(() => {
    const date = new Date()
    date.setDate(date.getDate() - 89)
    return toDateInput(date)
  })
  const [selected, setSelected] = useState(null)
  const [pendingStatus, setPendingStatus] = useState(null)
  const [state, setState] = useState('loading')
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    setState('loading')
    setError('')
    try {
      setItems(mockMode ? mockEstimations : await getEstimations())
      setState('ready')
    } catch (loadError) {
      setError(loadError.message)
      setState('error')
    }
  }, [mockMode])

  // Initial API synchronization is intentionally owned by this effect.
  // oxlint-disable-next-line react/set-state-in-effect
  useEffect(() => { load() }, [load])

  const visibleItems = useMemo(
    () => filterEstimations(items, { status, startDate, endDate }),
    [items, status, startDate, endDate],
  )

  const setPeriod = (days) => {
    const end = endDate ? new Date(`${endDate}T00:00:00`) : new Date()
    const start = new Date(end)
    start.setDate(end.getDate() - (days - 1))
    setStartDate(toDateInput(start))
  }

  const confirmStatus = async () => {
    if (!selected || !pendingStatus) return
    try {
      setState('updating')
      if (!mockMode) await updateEstimationStatus(selected.id, pendingStatus)
      setItems((current) => current.map((item) => item.id === selected.id ? { ...item, status: pendingStatus } : item))
      setSelected((current) => ({ ...current, status: pendingStatus }))
      setPendingStatus(null)
    } catch (updateError) {
      setError(updateError.message)
    } finally {
      setState('ready')
    }
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <a className="brand" href="/" aria-label="GlobalGates 홈">GG</a>
        <nav aria-label="주요 메뉴">
          <a href="/inquiry/chart">요약</a><a href="/inquiry/member-list">거래처</a>
          <a href="/inquiry/activity/list">활동</a><a className="active" href="/estimation/list">견적</a>
        </nav>
      </aside>

      <main>
        <header className="page-header">
          <div><p className="eyebrow">EXPERT WORKSPACE</p><h1>견적 요청</h1><p className="summary">받은 요청을 검토하고 거래 진행 여부를 관리합니다.</p></div>
          <div className="header-actions"><a className="primary-link" href={mockMode ? '/?view=register&mock=true' : '/?view=register'}>새 견적 요청</a><div className="count" aria-label={`전체 ${items.length}건`}><strong>{items.length}</strong><span>전체 요청</span></div></div>
        </header>

        <section className="toolbar" aria-label="견적 요청 필터">
          <label><span>상태</span><select value={status} onChange={(event) => setStatus(event.target.value)}><option value="all">전체</option><option value="requesting">요청중</option><option value="approve">승인됨</option><option value="reject">거절됨</option></select></label>
          <label><span>시작일</span><input type="date" value={startDate} onChange={(event) => setStartDate(event.target.value)} /></label>
          <label><span>종료일</span><input type="date" value={endDate} onChange={(event) => setEndDate(event.target.value)} /></label>
          <div className="periods" aria-label="빠른 기간">{periods.map(([label, days]) => <button key={label} type="button" onClick={() => setPeriod(days)}>{label}</button>)}</div>
        </section>

        {error && <div className="inline-error" role="alert">{error}</div>}
        {state === 'loading' && <StatePanel title="견적 요청을 불러오는 중입니다" />}
        {state === 'error' && <StatePanel title="목록을 불러오지 못했습니다" action="다시 시도" onAction={load} />}
        {state !== 'loading' && state !== 'error' && visibleItems.length === 0 && <StatePanel title="조건에 맞는 견적 요청이 없습니다" />}

        <section className="request-list" aria-live="polite">
          {visibleItems.map((item) => (
            <button className="request-row" type="button" key={item.id} onClick={() => setSelected(item)}>
              <div className="requester-avatar">{(item.requesterNickname || item.requesterEmail || '?')[0].toUpperCase()}</div>
              <div className="request-main">
                <div className="request-meta"><strong>{item.requesterNickname || item.requesterEmail || '요청자'}</strong><span>{item.createdDateTime || '-'}</span></div>
                <h2>{item.title || '견적 요청'}</h2><p>{item.content || '요청 내용이 없습니다.'}</p>
                <div className="tags">{item.tags?.length ? item.tags.map((tag) => <span key={tag.id || tag.tagName}>#{tag.tagName}</span>) : <span>#태그없음</span>}</div>
              </div>
              <div className={`status status-${normalizeStatus(item.status)}`}>{formatStatus(item.status)}</div>
            </button>
          ))}
        </section>
      </main>

      {selected && <div className="modal-layer" role="presentation" onMouseDown={(event) => event.target === event.currentTarget && setSelected(null)}>
        <section className="detail-modal" role="dialog" aria-modal="true" aria-labelledby="detail-title">
          <button className="icon-button close" type="button" aria-label="닫기" onClick={() => setSelected(null)}>×</button>
          <p className="eyebrow">ESTIMATION DETAIL</p><h2 id="detail-title">{selected.title || '견적 요청'}</h2><p className="detail-content">{selected.content || '요청 내용이 없습니다.'}</p>
          <dl><div><dt>요청자</dt><dd>{selected.requesterNickname || selected.requesterEmail || '-'}</dd></div><div><dt>수신자</dt><dd>{selected.receiverNickname || selected.receiverEmail || '-'}</dd></div><div><dt>위치</dt><dd>{selected.location || '위치 미등록'}</dd></div><div><dt>마감일</dt><dd>{selected.deadLine || '-'}</dd></div></dl>
          <div className="modal-actions"><button type="button" className="approve" disabled={state === 'updating'} onClick={() => setPendingStatus('approve')}>승인</button><button type="button" className="reject" disabled={state === 'updating'} onClick={() => setPendingStatus('reject')}>거절</button></div>
        </section>
      </div>}

      {pendingStatus && <div className="confirm-layer" role="presentation"><section className="confirm" role="alertdialog" aria-modal="true"><h2>{pendingStatus === 'approve' ? '견적 요청을 승인할까요?' : '견적 요청을 거절할까요?'}</h2><p>변경 결과는 요청자에게 표시됩니다.</p><div><button type="button" onClick={confirmStatus}>확인</button><button type="button" onClick={() => setPendingStatus(null)}>취소</button></div></section></div>}
    </div>
  )
}

function StatePanel({ title, action, onAction }) {
  return <section className="state-panel"><strong>{title}</strong>{action && <button type="button" onClick={onAction}>{action}</button>}</section>
}

function App() {
  const params = new URLSearchParams(window.location.search)
  return params.get('view') === 'register' ? <EstimationRegisterPage mockMode={params.get('mock') === 'true'} /> : <EstimationListPage />
}

export default App
