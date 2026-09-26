import assert from 'node:assert/strict'
import test from 'node:test'
import { filterEstimations, formatStatus, normalizeStatus } from '../src/domain/estimation.js'

const items = [
  { id: 1, status: 'requesting', createdDateTime: '2026-09-20 10:00' },
  { id: 2, status: 'approve', createdDateTime: '2026-09-10 10:00' },
  { id: 3, status: 'reject', createdDateTime: '2026-08-30 10:00' },
]

test('unknown statuses remain in the requesting group', () => {
  assert.equal(normalizeStatus(null), 'requesting')
  assert.equal(formatStatus('unknown'), '요청중')
})

test('filters by status and inclusive date range', () => {
  assert.deepEqual(filterEstimations(items, {
    status: 'approve', startDate: '2026-09-10', endDate: '2026-09-20',
  }).map(({ id }) => id), [2])
})

test('keeps items with an unparseable date visible', () => {
  const result = filterEstimations([{ id: 4, status: 'requesting', createdDateTime: null }], {
    status: 'all', startDate: '2026-09-01', endDate: '2026-09-30',
  })
  assert.equal(result.length, 1)
})
