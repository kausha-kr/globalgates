const requestJson = async (url, options = {}) => {
  const response = await fetch(url, { credentials: 'include', ...options, headers: { Accept: 'application/json', ...options.headers } })
  if (!response.ok) throw new Error(`요청 처리에 실패했습니다. (${response.status})`)
  return response.json()
}

export const getEstimations = async (page = 1) => {
  const data = await requestJson(`/api/estimations/list/${page}`)
  return data?.estimations ?? data?.content ?? data?.list ?? (Array.isArray(data) ? data : [])
}

export const updateEstimationStatus = (id, status) => requestJson(`/api/estimations/${id}/status`, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ status }) })

export const searchExperts = (keyword = '', page = 1) => {
  const params = new URLSearchParams({ page: String(page) })
  if (keyword.trim()) params.set('keyword', keyword.trim())
  return requestJson(`/api/estimations/experts?${params}`)
}

export const getProducts = (memberId) => requestJson(`/api/estimations/products?memberId=${memberId}`)

export const classifyEstimation = (payload) => requestJson('/api/ai/estimations/classify', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(payload),
})

export const createEstimation = (payload) => requestJson('/api/estimations/write', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(payload),
})
