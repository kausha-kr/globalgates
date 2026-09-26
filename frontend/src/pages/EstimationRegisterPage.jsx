import { useMemo, useState } from 'react'
import { classifyEstimation, createEstimation, getProducts, searchExperts } from '../api/estimations'
import { buildEstimationPayload, getAiReviewPresentation, initialEstimationForm, validateEstimationForm } from '../domain/estimationForm'
import { mockExperts, mockProducts } from '../mocks/estimationForm'

const emptyReview = null

export default function EstimationRegisterPage({ mockMode }) {
  const [query, setQuery] = useState('')
  const [experts, setExperts] = useState(mockMode ? mockExperts : [])
  const [expert, setExpert] = useState(null)
  const [products, setProducts] = useState([])
  const [product, setProduct] = useState(null)
  const [form, setForm] = useState(initialEstimationForm)
  const [tagInput, setTagInput] = useState('')
  const [errors, setErrors] = useState({})
  const [review, setReview] = useState(emptyReview)
  const [state, setState] = useState('idle')
  const [message, setMessage] = useState('')
  const [allowSubmit, setAllowSubmit] = useState(false)
  const reviewView = useMemo(() => getAiReviewPresentation(review), [review])

  const updateForm = (field, value) => {
    setForm((current) => ({ ...current, [field]: value }))
    setErrors((current) => ({ ...current, [field]: undefined }))
    setReview(emptyReview)
    setAllowSubmit(false)
  }

  const findExperts = async (event) => {
    event.preventDefault()
    setState('searching')
    setMessage('')
    try {
      if (mockMode) {
        const keyword = query.trim().toLowerCase()
        setExperts(mockExperts.filter((item) => [item.memberName, item.memberNickname, item.memberHandle].some((value) => value.toLowerCase().includes(keyword))))
      } else {
        const result = await searchExperts(query)
        setExperts(result?.experts ?? result?.content ?? result ?? [])
      }
    } catch (error) {
      setMessage(error.message)
    } finally {
      setState('idle')
    }
  }

  const chooseExpert = async (item) => {
    setExpert(item)
    setProduct(null)
    setErrors((current) => ({ ...current, expert: undefined, product: undefined }))
    setState('loading-products')
    try {
      const nextProducts = mockMode ? mockProducts.filter((entry) => entry.memberId === item.id) : await getProducts(item.id)
      setProducts(nextProducts?.products ?? nextProducts?.content ?? nextProducts ?? [])
    } catch (error) {
      setProducts([])
      setMessage(error.message)
    } finally {
      setState('idle')
    }
  }

  const addTag = () => {
    const tag = tagInput.trim().replace(/^#/, '')
    if (!tag || form.tags.includes(tag)) return
    if (form.tags.length >= 5) {
      setErrors((current) => ({ ...current, tags: '태그는 최대 5개까지 추가할 수 있습니다.' }))
      return
    }
    updateForm('tags', [...form.tags, tag])
    setTagInput('')
  }

  const checkForm = () => {
    const nextErrors = validateEstimationForm({ form, expert, product })
    setErrors(nextErrors)
    return Object.keys(nextErrors).length === 0
  }

  const runReview = async () => {
    if (!checkForm()) return null
    setState('reviewing')
    setReview({ status: 'checking' })
    setMessage('')
    try {
      const payload = buildEstimationPayload({ form, expert, product })
      const result = mockMode
        ? { prediction: form.summary.length + form.conditions.length >= 35 ? 'approve' : 'reject', probability: 0.91 }
        : await classifyEstimation(payload)
      setReview(result)
      setAllowSubmit((result.prediction || result.isEstimation) === 'approve')
      return result
    } catch (error) {
      const result = { status: 'unavailable', message: error.message }
      setReview(result)
      return result
    } finally {
      setState('idle')
    }
  }

  const submit = async () => {
    if (!checkForm()) return
    let currentReview = review
    if (!currentReview || currentReview.status === 'checking') currentReview = await runReview()
    const approved = (currentReview?.prediction || currentReview?.isEstimation) === 'approve'
    if (!approved && !allowSubmit) {
      setAllowSubmit(true)
      setMessage('AI 검토 결과를 확인해 주세요. 내용을 보완하거나, 현재 내용으로 한 번 더 등록을 눌러 진행할 수 있습니다.')
      return
    }
    setState('submitting')
    setMessage('')
    try {
      if (!mockMode) await createEstimation(buildEstimationPayload({ form, expert, product }))
      setState('success')
      setMessage('견적 요청을 등록했습니다. 목록에서 진행 상태를 확인할 수 있습니다.')
    } catch (error) {
      setState('idle')
      setMessage(error.message)
    }
  }

  return (
    <div className="app-shell register-shell">
      <aside className="sidebar">
        <a className="brand" href="/" aria-label="GlobalGates 홈">GG</a>
        <nav aria-label="주요 메뉴"><a href="/inquiry/chart">요약</a><a href="/inquiry/member-list">거래처</a><a href="/inquiry/activity/list">활동</a><a className="active" href="/estimation/list">견적</a></nav>
      </aside>
      <main>
        <header className="page-header register-header">
          <div><a className="back-link" href={mockMode ? '/?mock=true' : '/'}>← 견적 목록</a><p className="eyebrow">NEW ESTIMATION</p><h1>견적 요청 등록</h1><p className="summary">전문가의 상품을 선택하고 필요한 조건을 구체적으로 전달합니다.</p></div>
          <ol className="step-list" aria-label="등록 단계"><li className={expert ? 'done' : 'current'}>전문가</li><li className={product ? 'done' : expert ? 'current' : ''}>상품</li><li className={product ? 'current' : ''}>요청서</li></ol>
        </header>

        {message && <div className={state === 'success' ? 'success-message' : 'inline-error'} role="status">{message}</div>}

        <section className="register-section" aria-labelledby="expert-title">
          <div className="section-heading"><span>01</span><div><h2 id="expert-title">전문가 선택</h2><p>이름, 닉네임, 핸들로 검색할 수 있습니다.</p></div></div>
          <form className="expert-search" onSubmit={findExperts}><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="전문가 검색" aria-label="전문가 검색어" /><button type="submit" disabled={state === 'searching'}>{state === 'searching' ? '검색 중' : '검색'}</button></form>
          {errors.expert && <p className="field-error">{errors.expert}</p>}
          <div className="choice-grid">{experts.map((item) => <button key={item.id} type="button" className={`choice-card ${expert?.id === item.id ? 'selected' : ''}`} onClick={() => chooseExpert(item)}><span className="choice-avatar">{item.memberName[0]}</span><strong>{item.memberNickname || item.memberName}</strong><small>{item.memberHandle || item.memberEmail}</small></button>)}</div>
          {experts.length === 0 && <p className="empty-copy">검색 결과가 없습니다.</p>}
        </section>

        <section className="register-section" aria-labelledby="product-title">
          <div className="section-heading"><span>02</span><div><h2 id="product-title">상품 선택</h2><p>{expert ? `${expert.memberNickname || expert.memberName}의 상품입니다.` : '전문가를 먼저 선택해 주세요.'}</p></div></div>
          {errors.product && <p className="field-error">{errors.product}</p>}
          {state === 'loading-products' && <p className="empty-copy">상품을 불러오는 중입니다.</p>}
          <div className="product-grid">{products.map((item) => <button key={item.id} type="button" className={`product-choice ${product?.id === item.id ? 'selected' : ''}`} onClick={() => { setProduct(item); setErrors((current) => ({ ...current, product: undefined })); setReview(emptyReview) }}><span>{item.categoryName}</span><strong>{item.postTitle}</strong><p>{item.postContent}</p><b>{Number(item.productPrice).toLocaleString('ko-KR')}원</b></button>)}</div>
          {expert && state !== 'loading-products' && products.length === 0 && <p className="empty-copy">등록된 상품이 없습니다.</p>}
        </section>

        <section className="register-section" aria-labelledby="request-title">
          <div className="section-heading"><span>03</span><div><h2 id="request-title">요청서 작성</h2><p>작업 범위와 완료 기준을 구분해서 적어 주세요.</p></div></div>
          <div className="form-grid">
            <Field label="제목" error={errors.title} wide><input value={form.title} maxLength="80" onChange={(event) => updateForm('title', event.target.value)} placeholder="예: 팝업 스토어용 진열대 제작 견적 요청" /></Field>
            <Field label="요청 내용" error={errors.summary} wide><textarea value={form.summary} onChange={(event) => updateForm('summary', event.target.value)} placeholder="필요한 결과물과 사용 목적을 적어 주세요." /></Field>
            <Field label="조건 및 참고사항" error={errors.conditions} wide><textarea value={form.conditions} onChange={(event) => updateForm('conditions', event.target.value)} placeholder="수량, 크기, 소재, 예산 등 확인이 필요한 조건을 적어 주세요." /></Field>
            <Field label="작업 위치"><input value={form.location} onChange={(event) => updateForm('location', event.target.value)} placeholder="예: 서울 성동구" /></Field>
            <Field label="희망 마감일"><input type="date" value={form.deadline} onChange={(event) => updateForm('deadline', event.target.value)} /></Field>
            <Field label="태그" error={errors.tags} wide><div className="tag-editor"><input value={tagInput} onChange={(event) => setTagInput(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter') { event.preventDefault(); addTag() } }} placeholder="태그 입력 후 추가" /><button type="button" onClick={addTag}>추가</button></div><div className="editable-tags">{form.tags.map((tag) => <button type="button" key={tag} onClick={() => updateForm('tags', form.tags.filter((item) => item !== tag))}>#{tag} ×</button>)}</div></Field>
          </div>
        </section>

        <section className={`ai-review ${reviewView.tone}`} aria-live="polite"><div><p className="eyebrow">AI REQUEST CHECK</p><h2>{reviewView.title}</h2><p>{reviewView.message}</p></div><button type="button" onClick={runReview} disabled={state === 'reviewing' || state === 'submitting'}>{state === 'reviewing' ? '검토 중' : 'AI 검토'}</button></section>
        <div className="submit-bar"><a href={mockMode ? '/?mock=true' : '/'}>취소</a><button type="button" onClick={submit} disabled={state === 'submitting' || state === 'success'}>{state === 'submitting' ? '등록 중' : state === 'success' ? '등록 완료' : '견적 요청 등록'}</button></div>
      </main>
    </div>
  )
}

function Field({ label, error, wide, children }) {
  return <label className={wide ? 'wide' : ''}><span>{label}</span>{children}{error && <small className="field-error">{error}</small>}</label>
}
