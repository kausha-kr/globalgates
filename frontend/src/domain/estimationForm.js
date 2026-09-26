export const initialEstimationForm = {
  title: '',
  summary: '',
  conditions: '',
  location: '',
  deadline: '',
  tags: [],
}

export const validateEstimationForm = ({ form, expert, product }) => {
  const errors = {}
  if (!expert) errors.expert = '견적 요청을 보낼 전문가를 선택해 주세요.'
  if (!product) errors.product = '견적을 요청할 상품을 선택해 주세요.'
  if (!form.title.trim()) errors.title = '요청 제목을 입력해 주세요.'
  if (form.title.trim().length > 80) errors.title = '제목은 80자 이내로 입력해 주세요.'
  if (!form.summary.trim()) errors.summary = '요청 내용을 간단히 적어 주세요.'
  if (!form.conditions.trim()) errors.conditions = '요청 조건을 입력해 주세요.'
  if (form.tags.length > 5) errors.tags = '태그는 최대 5개까지 추가할 수 있습니다.'
  return errors
}

export const buildEstimationPayload = ({ form, expert, product }) => ({
  receiverId: expert?.id ?? null,
  receiverEmail: expert?.memberEmail ?? null,
  productId: product?.id ?? null,
  title: form.title.trim(),
  content: [form.summary.trim(), form.conditions.trim()].filter(Boolean).join('\n'),
  location: form.location.trim() || null,
  deadLine: form.deadline || null,
  status: 'requesting',
  productName: product?.postTitle ?? '',
  productContent: product?.postContent ?? '',
  productPrice: Number(product?.productPrice ?? 0),
  productStock: Number(product?.productStock ?? 0),
  productCategory: product?.categoryName || form.tags[0] || 'Unknown',
  tagCount: form.tags.length,
  tags: form.tags.map((tagName) => ({ tagName })),
})

export const getAiReviewPresentation = (result) => {
  if (!result) return { tone: 'idle', title: '검토 전', message: '필수 항목을 입력하면 AI 검토를 시작할 수 있습니다.' }
  if (result.status === 'checking') return { tone: 'checking', title: '검토 중', message: '입력한 요청 내용을 확인하고 있습니다.' }
  if (result.status === 'unavailable' || result.prediction === 'unavailable') return { tone: 'error', title: 'AI 연결 실패', message: result.message || 'AI 서버와 연결하지 못했습니다.' }
  if (result.status === 'needs_input') return { tone: 'reject', title: '내용 보완 필요', message: result.message || '요청 내용을 조금 더 구체적으로 작성해 주세요.' }
  const probability = typeof result.probability === 'number' ? `${Math.round(result.probability * 100)}%` : null
  if ((result.prediction || result.isEstimation) === 'approve') return { tone: 'approve', title: '등록 가능', message: probability ? `견적 요청으로 판단한 점수는 ${probability}입니다.` : '견적 요청으로 등록할 수 있습니다.' }
  return { tone: 'reject', title: '한 번 더 확인해 주세요', message: probability ? `보완이 필요할 가능성은 ${probability}입니다.` : '제목과 요청 조건을 다시 확인해 주세요.' }
}
