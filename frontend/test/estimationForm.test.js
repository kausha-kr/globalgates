import assert from 'node:assert/strict'
import test from 'node:test'
import { buildEstimationPayload, getAiReviewPresentation, initialEstimationForm, validateEstimationForm } from '../src/domain/estimationForm.js'

const expert = { id: 7, memberEmail: 'expert@example.com' }
const product = { id: 9, postTitle: '상품', postContent: '설명', productPrice: '12000', productStock: '2', categoryName: '디자인' }

test('필수 선택과 입력값을 함께 검증한다', () => {
  const errors = validateEstimationForm({ form: initialEstimationForm, expert: null, product: null })
  assert.deepEqual(Object.keys(errors).sort(), ['conditions', 'expert', 'product', 'summary', 'title'])
})

test('화면 상태를 API 등록 형식으로 변환한다', () => {
  const payload = buildEstimationPayload({ form: { ...initialEstimationForm, title: ' 제목 ', summary: '요청 내용', conditions: '작업 조건', tags: ['긴급'] }, expert, product })
  assert.equal(payload.receiverId, 7)
  assert.equal(payload.productId, 9)
  assert.equal(payload.title, '제목')
  assert.equal(payload.content, '요청 내용\n작업 조건')
  assert.equal(payload.productPrice, 12000)
  assert.deepEqual(payload.tags, [{ tagName: '긴급' }])
})

test('AI 승인 결과를 사용자 문구로 정리한다', () => {
  assert.deepEqual(getAiReviewPresentation({ prediction: 'approve', probability: 0.934 }), { tone: 'approve', title: '등록 가능', message: '견적 요청으로 판단한 점수는 93%입니다.' })
})
