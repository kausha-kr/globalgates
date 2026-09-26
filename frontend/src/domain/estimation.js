export const normalizeStatus = (status) => {
  const value = String(status ?? '').trim().toLowerCase()
  return ['approve', 'reject'].includes(value) ? value : 'requesting'
}
export const formatStatus = (status) => ({ approve: '승인됨', reject: '거절됨', requesting: '요청중' })[normalizeStatus(status)]
const normalizeDate = (value) => String(value ?? '').match(/^\d{4}-\d{2}-\d{2}/)?.[0] ?? ''
export const filterEstimations = (items, { status, startDate, endDate }) => items.filter((item) => {
  const date = normalizeDate(item.createdDateTime)
  return (status === 'all' || normalizeStatus(item.status) === status) && (!startDate || !date || date >= startDate) && (!endDate || !date || date <= endDate)
})
